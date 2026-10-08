require "rails_helper"

RSpec.describe "Admin orders API", type: :request do
  let(:headers) { auth_headers_for(create(:user, :admin)) }

  it "lists orders for every customer" do
    first_order = create(:order)
    second_order = create(:order)

    get "/api/v1/admin/orders", headers: headers

    expect(response).to have_http_status(:ok)
    ids = json_body.map { |order| order["id"] }
    expect(ids).to contain_exactly(first_order.id, second_order.id)
    expect(json_body.first["user"]["email"]).to be_present
    expect(json_body.first["user"]).not_to have_key("password_digest")
  end

  it "filters orders by customer" do
    order = create(:order)
    create(:order)

    get "/api/v1/admin/orders", params: { user_id: order.user_id }, headers: headers

    expect(response).to have_http_status(:ok)
    expect(json_body.map { |row| row["id"] }).to eq([ order.id ])
  end

  it "shows one order" do
    order = create(:order)

    get "/api/v1/admin/orders/#{order.id}", headers: headers

    expect(response).to have_http_status(:ok)
    expect(json_body["id"]).to eq(order.id)
    expect(json_body["user"]["id"]).to eq(order.user_id)
  end
end
