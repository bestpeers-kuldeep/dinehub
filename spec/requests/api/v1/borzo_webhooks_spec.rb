require "rails_helper"

RSpec.describe "Borzo delivery webhooks", type: :request do
  let(:secret) { "callback-secret" }
  let(:order) { create(:order, status: :confirmed) }
  let!(:delivery) do
    create(:delivery, order: order, provider: "borzo", status: :requested, external_order_id: "55", external_delivery_id: "9")
  end

  around do |example|
    previous = ENV["BORZO_CALLBACK_SECRET"]
    ENV["BORZO_CALLBACK_SECRET"] = secret
    example.run
  ensure
    ENV["BORZO_CALLBACK_SECRET"] = previous
  end

  def post_callback(payload)
    body = payload.to_json
    signature = OpenSSL::HMAC.hexdigest("SHA256", secret, body)

    post "/api/v1/delivery_webhooks/borzo",
         params: body,
         headers: {
           "CONTENT_TYPE" => "application/json",
           "X-DV-Signature" => signature
         }
  end

  it "updates the order when Borzo reports the delivery is finished" do
    post_callback(
      event_type: "delivery_changed",
      delivery: {
        delivery_id: 9,
        order_id: 55,
        status: "finished",
        tracking_url: "https://track.example/9",
        courier: { name: "Ravi", surname: "K", phone: "999" }
      }
    )

    expect(response).to have_http_status(:ok)
    expect(delivery.reload).to be_delivered
    expect(delivery.tracking_url).to eq("https://track.example/9")
    expect(delivery.rider_name).to eq("Ravi K")
    expect(order.reload).to be_completed
  end

  it "updates the order from an order callback" do
    post_callback(
      event_type: "order_changed",
      order: {
        order_id: 55,
        status: "active",
        points: [
          { client_order_id: order.id.to_s },
          { delivery_id: 9, tracking_url: "https://track.example/9", delivery: { status: "parcel_picked_up" } }
        ]
      }
    )

    expect(response).to have_http_status(:ok)
    expect(delivery.reload).to be_picked_up
    expect(order.reload).to be_ready
  end

  it "rejects a callback with a bad signature" do
    post "/api/v1/delivery_webhooks/borzo",
         params: { event_type: "order_changed", order: { order_id: 55, status: "completed" } }.to_json,
         headers: { "CONTENT_TYPE" => "application/json", "X-DV-Signature" => "nope" }

    expect(response).to have_http_status(:unauthorized)
    expect(order.reload).to be_confirmed
  end
end
