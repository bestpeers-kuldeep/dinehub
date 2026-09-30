require "rails_helper"

RSpec.describe "Cashfree payment webhook", type: :request do
  let(:secret) { "test-webhook-secret" }
  let(:timestamp) { Time.current.to_i.to_s }
  let(:user) { create(:user) }
  let(:cart) { create(:cart, user: user) }
  let(:order) { create(:order, user: user, cart: cart) }
  let!(:payment) { create(:payment, order: order, gateway_order_id: "ORDER_#{order.id}") }

  before do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with("CASHFREE_SECRET_KEY").and_return(secret)
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
    it "marks the payment successful, completes the order and consumes the cart" do
      post_webhook(payload_for("SUCCESS"))

      expect(response).to have_http_status(:ok)

      payment.reload
      expect(payment).to be_successful
      expect(payment.gateway_payment_id).to eq("987654")
      expect(payment.metadata.dig("webhook", "data", "payment", "payment_status")).to eq("SUCCESS")
      expect(order.reload).to be_completed
      expect(cart.reload).to be_completed
      expect(cart.deleted_at).to be_present
    end

    it "does not touch a newer cart the user started after checkout" do
      cart.update!(status: :completed, deleted_at: 1.hour.ago)
      newer_cart = create(:cart, user: user)

      post_webhook(payload_for("SUCCESS"))

      expect(response).to have_http_status(:ok)
      expect(newer_cart.reload).to be_active
      expect(newer_cart.deleted_at).to be_nil
    end

    it "is idempotent when the same event is delivered twice" do
      2.times { post_webhook(payload_for("SUCCESS")) }

      expect(response).to have_http_status(:ok)
      expect(payment.reload).to be_successful
      expect(order.reload).to be_completed
    end

    it "recovers an order whose earlier attempt failed" do
      post_webhook(payload_for("USER_DROPPED"))
      expect(order.reload).to be_cancelled

      post_webhook(payload_for("SUCCESS", cf_payment_id: 111))

      expect(payment.reload).to be_successful
      expect(payment.gateway_payment_id).to eq("111")
      expect(order.reload).to be_completed
    end
  end

  describe "FAILED / USER_DROPPED" do
    it "marks the payment failed, cancels the order and keeps the cart" do
      post_webhook(payload_for("FAILED"))

      expect(response).to have_http_status(:ok)

      payment.reload
      expect(payment).to be_failed
      expect(payment.metadata["final_payment_status"]).to eq("FAILED")
      expect(order.reload).to be_cancelled
      expect(cart.reload).to be_active
      expect(cart.deleted_at).to be_nil
    end

    it "never downgrades a successful payment" do
      post_webhook(payload_for("SUCCESS"))
      post_webhook(payload_for("FAILED"))

      expect(response).to have_http_status(:ok)
      expect(payment.reload).to be_successful
      expect(order.reload).to be_completed
    end
  end

  it "acknowledges and ignores intermediate statuses" do
    post_webhook(payload_for("PENDING"))

    expect(response).to have_http_status(:ok)
    expect(payment.reload).to be_pending
    expect(order.reload).to be_pending
  end
end
