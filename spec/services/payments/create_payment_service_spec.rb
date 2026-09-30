require "rails_helper"

RSpec.describe Payments::CreatePaymentService, type: :service do
  let(:order) { create(:order) }
  let(:gateway_response) do
    { "order_id" => "ORDER_#{order.id}", "payment_session_id" => "session_abc" }
  end
  let(:gateway_double) { instance_double(Payments::Providers::Cashfree::CreateOrder, call: gateway_response) }

  before do
    # CreateOrder reads API_URL while the class is loading. These examples stub
    # that class, so the value is only needed to let the file load.
    ENV["API_URL"] ||= "https://sandbox.cashfree.com/pg/orders"

    allow(Payments::Providers::Cashfree::CreateOrder).to receive(:new).with(order).and_return(gateway_double)
  end

  it "creates a pending payment with the gateway identifiers" do
    payment = described_class.new(order).call

    expect(payment).to be_persisted
    expect(payment).to be_pending
    expect(payment.gateway).to eq("cashfree")
    expect(payment.amount).to eq(order.total)
    expect(payment.gateway_order_id).to eq("ORDER_#{order.id}")
    expect(payment.payment_session_id).to eq("session_abc")
  end

  it "reuses the existing payment on retry instead of creating a second one" do
    existing = create(:payment, order: order, status: :failed, gateway_order_id: nil)

    payment = described_class.new(order).call

    expect(payment.id).to eq(existing.id)
    expect(payment).to be_pending
    expect(Payment.where(order_id: order.id).count).to eq(1)
  end

  it "refuses an order that is already paid" do
    create(:payment, order: order, status: :successful)

    expect { described_class.new(order).call }
      .to raise_error(Payments::Errors::OrderNotPayable, /already paid/)
  end

  it "refuses a cancelled order" do
    order.update!(status: :cancelled)

    expect { described_class.new(order).call }
      .to raise_error(Payments::Errors::OrderNotPayable, /cancelled/)
    expect(Payment.where(order_id: order.id)).not_to exist
  end

  it "does not persist gateway data when the gateway call fails" do
    allow(gateway_double).to receive(:call).and_raise(Payments::Errors::Gateway, "boom")

    expect { described_class.new(order).call }.to raise_error(Payments::Errors::Gateway)

    payment = Payment.find_by(order_id: order.id)
    expect(payment).to be_pending
    expect(payment.gateway_order_id).to be_nil
  end

  it "rejects unknown gateways" do
    expect { described_class.new(order, gateway: "paypal").call }
      .to raise_error(ArgumentError, /Unsupported payment gateway/)
  end

  it "reuses a payment that already has a session and does not call the gateway" do
    existing = create(:payment, order: order, payment_session_id: "session_existing")

    expect(Payments::Providers::Cashfree::CreateOrder).not_to receive(:new)

    payment = described_class.new(order).call

    expect(payment.id).to eq(existing.id)
    expect(payment.payment_session_id).to eq("session_existing")
  end

  it "does not overwrite a payment the webhook already marked successful" do
    allow(gateway_double).to receive(:call) do
      Payment.find_by!(order_id: order.id).update!(
        status: :successful,
        gateway_payment_id: "cf_1",
        gateway_order_id: "ORDER_FROM_WEBHOOK"
      )
      order.update!(status: :completed)
      gateway_response
    end

    payment = described_class.new(order).call

    expect(payment).to be_successful
    expect(payment.gateway_payment_id).to eq("cf_1")
    expect(payment.gateway_order_id).to eq("ORDER_FROM_WEBHOOK")
    expect(order.reload).to be_completed
  end
end
