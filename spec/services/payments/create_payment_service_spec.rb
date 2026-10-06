require "rails_helper"

RSpec.describe Payments::CreatePaymentService, type: :service do
  let(:user) { create(:user) }
  let(:cart) { create(:cart, user: user) }
  let(:address) { create(:delivery_address, user: user) }
  let!(:cart_item) { create(:cart_item, cart: cart, quantity: 2, unit_price: 10) }
  let(:gateway_response) do
    { "order_id" => "CHECKOUT_1", "payment_session_id" => "session_abc" }
  end
  let(:gateway_double) { instance_double(Payments::Providers::Cashfree::CreateOrder, call: gateway_response) }

  before do
    # CreateOrder reads API_URL while the class is loading. These examples stub
    # that class, so the value is only needed to let the file load.
    ENV["API_URL"] ||= "https://sandbox.cashfree.com/pg/orders"

    allow(Payments::Providers::Cashfree::CreateOrder).to receive(:new).and_return(gateway_double)
  end

  def start_payment
    described_class.new(user, cart_id: cart.id, delivery_address_id: address.id).call
  end

  it "creates a pending payment from the cart and does not create an order" do
    payment = start_payment

    expect(payment).to be_persisted
    expect(payment).to be_pending
    expect(payment.order).to be_nil
    expect(payment.cart).to eq(cart)
    expect(payment.delivery_address).to eq(address)
    expect(payment.amount).to eq(20)
    expect(payment.gateway_order_id).to eq("CHECKOUT_1")
    expect(payment.payment_session_id).to eq("session_abc")
    expect(payment.metadata.dig("checkout", "items").size).to eq(1)
    expect(Order.count).to eq(0)
  end

  it "reuses the open checkout on retry instead of creating a second payment" do
    existing = create(
      :payment,
      cart: cart,
      order: nil,
      delivery_address: address,
      status: :pending,
      gateway_order_id: nil,
      payment_session_id: nil
    )

    payment = start_payment

    expect(payment.id).to eq(existing.id)
    expect(payment).to be_pending
    expect(Payment.where(cart_id: cart.id).count).to eq(1)
  end

  it "refuses an empty cart" do
    cart_item.destroy!

    expect { start_payment }.to raise_error(Orders::Errors::CartEmpty, /empty/)
    expect(Payment.where(cart_id: cart.id)).not_to exist
  end

  it "does not persist gateway data when the gateway call fails" do
    allow(gateway_double).to receive(:call).and_raise(Payments::Errors::Gateway, "boom")

    expect { start_payment }.to raise_error(Payments::Errors::Gateway)

    payment = Payment.find_by(cart_id: cart.id)
    expect(payment).to be_pending
    expect(payment.gateway_order_id).to be_nil
    expect(payment.order).to be_nil
  end

  it "rejects unknown gateways" do
    expect {
      described_class.new(user, cart_id: cart.id, delivery_address_id: address.id, gateway: "paypal").call
    }.to raise_error(ArgumentError, /Unsupported payment gateway/)
  end

  it "reuses a payment that already has a session and does not call the gateway" do
    existing = create(
      :payment,
      cart: cart,
      order: nil,
      delivery_address: address,
      payment_session_id: "session_existing"
    )

    expect(Payments::Providers::Cashfree::CreateOrder).not_to receive(:new)

    payment = start_payment

    expect(payment.id).to eq(existing.id)
    expect(payment.payment_session_id).to eq("session_existing")
  end

  it "does not overwrite a payment the webhook already marked successful" do
    allow(gateway_double).to receive(:call) do
      payment = Payment.find_by!(cart_id: cart.id)
      order = create(:order, user: user, cart: cart, status: :confirmed, delivery_address: address)
      payment.update!(
        status: :successful,
        order: order,
        gateway_payment_id: "cf_1",
        gateway_order_id: "CHECKOUT_FROM_WEBHOOK"
      )
      gateway_response
    end

    payment = start_payment

    expect(payment).to be_successful
    expect(payment.gateway_payment_id).to eq("cf_1")
    expect(payment.gateway_order_id).to eq("CHECKOUT_FROM_WEBHOOK")
    expect(payment.order).to be_confirmed
  end
end
