require "rails_helper"

RSpec.describe "Admin orders API", type: :request do
  let(:headers) { auth_headers_for(create(:user, :admin)) }

  it "lists orders for every customer" do
    first_order = create(:order)
    second_order = create(:order)

    get "/api/v1/admin/orders", headers: headers

    expect(response).to have_http_status(:ok)
    ids = json_body.fetch("data").map { |order| order["id"] }
    expect(ids).to contain_exactly(first_order.id, second_order.id)
    expect(json_body.dig("pagination", "total_count")).to eq(2)
    expect(json_body["data"].first["user"]["email"]).to be_present
    expect(json_body["data"].first["user"]).not_to have_key("password_digest")
  end

  it "filters orders by customer" do
    order = create(:order)
    create(:order)

    get "/api/v1/admin/orders", params: { user_id: order.user_id }, headers: headers

    expect(response).to have_http_status(:ok)
    expect(json_body.fetch("data").map { |row| row["id"] }).to eq([ order.id ])
  end

  it "shows one order" do
    order = create(:order)

    get "/api/v1/admin/orders/#{order.id}", headers: headers

    expect(response).to have_http_status(:ok)
    expect(json_body["id"]).to eq(order.id)
    expect(json_body["user"]["id"]).to eq(order.user_id)
  end

  it "cancels the Borzo delivery when an admin cancels the order" do
    order = create(:order, status: :confirmed)
    create(:delivery, order: order, provider: "borzo", status: :requested, external_order_id: "55")
    client = instance_double(Deliveries::Providers::Borzo::Client)
    allow(Deliveries::Providers::Borzo::Client).to receive(:new).and_return(client)
    allow(client).to receive(:post).with("cancel-order", { order_id: 55 }).and_return(
      "is_successful" => true,
      "order" => { "status" => "canceled" }
    )

    patch "/api/v1/admin/orders/#{order.id}",
          params: { status: "cancelled" }.to_json,
          headers: headers.merge("CONTENT_TYPE" => "application/json")

    expect(response).to have_http_status(:ok)
    expect(order.reload).to be_cancelled
    expect(order.delivery.reload).to be_cancelled
  end

  it "leaves Borzo alone when an admin moves the order through the kitchen" do
    order = create(:order, status: :confirmed)
    create(:delivery, order: order, provider: "borzo", status: :requested, external_order_id: "55")
    expect(Deliveries::Providers::Borzo::Client).not_to receive(:new)

    patch "/api/v1/admin/orders/#{order.id}",
          params: { status: "preparing" }.to_json,
          headers: headers.merge("CONTENT_TYPE" => "application/json")

    expect(response).to have_http_status(:ok)
    expect(order.reload).to be_preparing
    expect(order.delivery.reload).to be_requested
  end

  it "refreshes tracking from Borzo and updates the order" do
    order = create(:order, status: :preparing)
    create(:delivery, order: order, provider: "borzo", status: :requested, external_order_id: "55")
    client = instance_double(Deliveries::Providers::Borzo::Client)
    allow(Deliveries::Providers::Borzo::Client).to receive(:new).and_return(client)
    allow(client).to receive(:get).with("orders", order_id: "55").and_return(
      "orders" => [
        {
          "order_id" => 55,
          "status" => "active",
          "points" => [
            { "delivery_id" => 9, "tracking_url" => "https://track.example/9", "delivery" => { "status" => "courier_assigned" } }
          ]
        }
      ]
    )
    allow(client).to receive(:get).with("courier", order_id: "55").and_return(
      "courier" => { "name" => "Ravi", "surname" => "K", "phone" => "999", "latitude" => "19.1", "longitude" => "72.8" }
    )

    get "/api/v1/admin/orders/#{order.id}/tracking", headers: headers

    expect(response).to have_http_status(:ok)
    expect(json_body["order_status"]).to eq("ready")
    expect(json_body.dig("delivery", "status")).to eq("assigned")
    expect(json_body.dig("delivery", "tracking_url")).to eq("https://track.example/9")
    expect(json_body.dig("delivery", "rider_name")).to eq("Ravi K")
    expect(order.reload).to be_ready
  end
end
