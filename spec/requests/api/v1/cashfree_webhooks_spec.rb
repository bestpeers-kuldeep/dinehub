require "rails_helper"

RSpec.describe "Cashfree payment webhook", type: :request do
  let(:secret) { "test-webhook-secret" }
  let(:timestamp) { Time.current.to_i.to_s }
  let(:user) { create(:user) }
  let(:cart) { create(:cart, user: user) }
  let(:menu_item) { create(:menu_item, name: "Margherita", price: 10) }
  let!(:cart_item) { create(:cart_item, cart: cart, menu_item: menu_item, quantity: 2, unit_price: 10) }
  let(:address) { create(:delivery_address, user: user) }
  let!(:payment) do
    create(
      :payment,
      cart: cart,
      order: nil,
      delivery_address: address,
      amount: 20,
      gateway_order_id: "CHECKOUT_100",
      metadata: {
        "checkout" => {
          "subtotal" => "20.0",
          "tax" => "0.0",
          "total" => "20.0",
          "items" => [
            {
              "menu_item_id" => menu_item.id,
              "name" => menu_item.name,
              "quantity" => 2,
              "unit_price" => "10.0"
            }
          ]
        }
      }
    )
  end

  before do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with("CASHFREE_SECRET_KEY").and_return(secret)
    allow(Deliveries::PlaceDeliveryService).to receive(:new) do |order|
      service = instance_double(Deliveries::PlaceDeliveryService)
      allow(service).to receive(:call) do
        order.delivery || order.create_delivery!(provider: "borzo", status: :requested)
      end
      service
    end
  end

  def payload_for(status, cf_payment_id: 987_654)
    {
      type: "PAYMENT_SUCCESS_WEBHOOK",
      data: {
        order: { order_id: payment.gateway_order_id, order_amount: 20.0 },
        payment: { cf_payment_id: cf_payment_id, payment_status: status }
      }
    }.to_json
  end

  def sign(body, ts = timestamp, key = secret)
    Base64.strict_encode64(OpenSSL::HMAC.digest("SHA256", key, "#{ts}#{body}"))
  end

  def post_webhook(body, signature: sign(body), ts: timestamp)
    post "/api/v1/payments/cashfree/webhook",
         params: body,
         headers: {
           "CONTENT_TYPE" => "application/json",
           "x-webhook-signature" => signature,
           "x-webhook-timestamp" => ts
         }
  end

  describe "signature verification" do
    it "rejects a request without a signature" do
      post_webhook(payload_for("SUCCESS"), signature: nil)

      expect(response).to have_http_status(:unauthorized)
      expect(payment.reload).to be_pending
      expect(payment.order).to be_nil
    end

    it "rejects a tampered body" do
      body = payload_for("SUCCESS")
      post_webhook(body.sub("SUCCESS", "FAILED"), signature: sign(body))

      expect(response).to have_http_status(:unauthorized)
      expect(payment.reload).to be_pending
    end

    it "rejects a signature produced with a different secret" do
      body = payload_for("SUCCESS")
      post_webhook(body, signature: sign(body, timestamp, "wrong"))

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "payload validation" do
    it "returns 400 for non-JSON bodies" do
      post_webhook("not json")

      expect(response).to have_http_status(:bad_request)
    end

    it "returns 400 when the order id is missing" do
      post_webhook({ data: { payment: { payment_status: "SUCCESS" } } }.to_json)

      expect(response).to have_http_status(:bad_request)
      expect(json_body["error"]).to match(/order_id/)
    end

    it "returns 404 for an unknown gateway order" do
      body = { data: { order: { order_id: "ORDER_UNKNOWN" }, payment: { payment_status: "SUCCESS" } } }.to_json
      post_webhook(body)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "SUCCESS" do
    it "creates a confirmed order from the cart and soft-deletes that cart" do
      post_webhook(payload_for("SUCCESS"))

      expect(response).to have_http_status(:ok)

      payment.reload
      expect(payment).to be_successful
      expect(payment.gateway_payment_id).to eq("987654")
      expect(payment.metadata.dig("webhook", "data", "payment", "payment_status")).to eq("SUCCESS")

      order = payment.order
      expect(order).to be_confirmed
      expect(order.user).to eq(user)
      expect(order.cart).to eq(cart)
      expect(order.delivery_address).to eq(address)
      expect(order.total).to eq(20)
      expect(order.order_items.map(&:name)).to eq([ "Margherita" ])

      expect(cart.reload).to be_completed
      expect(cart.deleted_at).to be_present
      expect { create(:cart, user: user) }.not_to raise_error
    end

    it "does not touch a newer cart the user started after checkout" do
      cart.update!(status: :completed, deleted_at: 1.hour.ago)
      newer_cart = create(:cart, user: user)

      post_webhook(payload_for("SUCCESS"))

      expect(response).to have_http_status(:ok)
      expect(newer_cart.reload).to be_active
      expect(newer_cart.deleted_at).to be_nil
      expect(payment.reload.order.cart).to eq(cart)
    end

    it "is idempotent when the same event is delivered twice" do
      2.times { post_webhook(payload_for("SUCCESS")) }

      expect(response).to have_http_status(:ok)
      expect(payment.reload).to be_successful
      expect(payment.order).to be_confirmed
      expect(user.orders.count).to eq(1)
    end

    it "confirms the same order when a later success arrives after a failed attempt" do
      post_webhook(payload_for("USER_DROPPED"))
      failed_order = payment.reload.order
      expect(failed_order).to be_cancelled
      expect(cart.reload).to be_active

      post_webhook(payload_for("SUCCESS", cf_payment_id: 111))

      expect(payment.reload).to be_successful
      expect(payment.gateway_payment_id).to eq("111")
      expect(payment.order).to eq(failed_order)
      expect(failed_order.reload).to be_confirmed
      expect(user.orders.count).to eq(1)
      expect(cart.reload.deleted_at).to be_present
    end
  end

  describe "FAILED / USER_DROPPED" do
    it "creates a cancelled order and keeps the cart so the customer can retry" do
      post_webhook(payload_for("FAILED"))

      expect(response).to have_http_status(:ok)

      payment.reload
      expect(payment).to be_failed
      expect(payment.order).to be_cancelled
      expect(payment.order.order_items.map(&:name)).to eq([ "Margherita" ])
      expect(payment.metadata["final_payment_status"]).to eq("FAILED")
      expect(cart.reload).to be_active
      expect(cart.deleted_at).to be_nil
      expect(user.orders.count).to eq(1)
    end

    it "never downgrades a successful payment" do
      post_webhook(payload_for("SUCCESS"))
      post_webhook(payload_for("FAILED"))

      expect(response).to have_http_status(:ok)
      expect(payment.reload).to be_successful
      expect(payment.order).to be_confirmed
    end
  end

  it "records a pending webhook and does not create an order" do
    post_webhook(payload_for("PENDING"))

    expect(response).to have_http_status(:ok)
    expect(payment.reload).to be_pending
    expect(payment.metadata.dig("webhook", "data", "payment", "payment_status")).to eq("PENDING")
    expect(payment.order).to be_nil
    expect(cart.reload).to be_active
  end

  it "creates a cancelled order when Cashfree cancels the payment" do
    post_webhook(payload_for("CANCELLED"))

    expect(response).to have_http_status(:ok)
    expect(payment.reload).to be_cancelled
    expect(payment.metadata["final_payment_status"]).to eq("CANCELLED")
    expect(payment.order).to be_cancelled
    expect(cart.reload).to be_active
    expect(cart.deleted_at).to be_nil
  end

  it "does not reopen a failed payment when a later pending webhook arrives" do
    post_webhook(payload_for("FAILED"))
    post_webhook(payload_for("PENDING"))

    expect(response).to have_http_status(:ok)
    expect(payment.reload).to be_failed
    expect(payment.order).to be_cancelled
    expect(user.orders.count).to eq(1)
  end
end
