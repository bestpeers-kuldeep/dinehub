require "rails_helper"

RSpec.describe "Payments", type: :request do
  let(:user) { create(:user) }
  let(:cart) { create(:cart, user: user) }
  let(:menu_item) { create(:menu_item, name: "Margherita", price: 10) }
  let!(:cart_item) { create(:cart_item, cart: cart, menu_item: menu_item, quantity: 2, unit_price: 10) }
  let(:address) { create(:delivery_address, user: user) }

  def sign_in
    cookies[:jwt] = JsonWebToken.encode({ user_id: user.id })
  end

  before do
    ENV["API_URL"] ||= "https://sandbox.cashfree.com/pg/orders"
    allow(Payments::Providers::Cashfree::CreateOrder).to receive(:new).and_return(
      instance_double(
        Payments::Providers::Cashfree::CreateOrder,
        call: { "order_id" => "CHECKOUT_SPEC", "payment_session_id" => "session_abc" }
      )
    )
  end

  it "starts payment from the cart and does not create an order" do
    sign_in

    post "/api/v1/payments",
         params: { cart_id: cart.id, delivery_address_id: address.id }.to_json,
         headers: { "CONTENT_TYPE" => "application/json" }

    expect(response).to have_http_status(:ok)
    expect(json_body.dig("payment", "payment_session_id")).to eq("session_abc")
    expect(json_body.dig("payment", "status")).to eq("pending")
    expect(Order.count).to eq(0)
    expect(cart.reload).to be_active
  end

  it "rejects checkout without a signed-in user" do
    post "/api/v1/payments",
         params: { cart_id: cart.id, delivery_address_id: address.id }.to_json,
         headers: { "CONTENT_TYPE" => "application/json" }

    expect(response).to have_http_status(:unauthorized)
  end
end
