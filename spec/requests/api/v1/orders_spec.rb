require "rails_helper"

RSpec.describe "Orders", type: :request do
  let(:user) { create(:user) }
  let(:order) { create(:order, user: user, status: :confirmed) }

  def sign_in
    cookies[:jwt] = JsonWebToken.encode({ user_id: user.id })
  end

  it "does not expose order creation" do
    sign_in

    post "/api/v1/orders", params: { cart_id: order.cart_id }.to_json,
                           headers: { "CONTENT_TYPE" => "application/json" }

    expect(response).to have_http_status(:not_found)
  end

  it "moves an order forward through the kitchen statuses" do
    sign_in

    patch "/api/v1/orders/#{order.id}",
          params: { status: "preparing" }.to_json,
          headers: { "CONTENT_TYPE" => "application/json" }

    expect(response).to have_http_status(:ok)
    expect(order.reload).to be_preparing

    patch "/api/v1/orders/#{order.id}",
          params: { status: "ready" }.to_json,
          headers: { "CONTENT_TYPE" => "application/json" }

    expect(order.reload).to be_ready
  end

  it "rejects a status jump and a backward move" do
    sign_in

    patch "/api/v1/orders/#{order.id}",
          params: { status: "completed" }.to_json,
          headers: { "CONTENT_TYPE" => "application/json" }

    expect(response).to have_http_status(:unprocessable_entity)
    expect(order.reload).to be_confirmed
  end
end
