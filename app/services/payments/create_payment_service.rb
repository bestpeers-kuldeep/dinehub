module Payments
  class CreatePaymentService
    def initialize(order, gateway: "cashfree")
      @order = order
      @gateway = gateway
    end

    def call
      payment = find_or_create_payment

      gateway_response = gateway_service.new(@order).call

      payment.update!(
        gateway_order_id: gateway_response["order_id"],
        payment_session_id: gateway_response["payment_session_id"],
        metadata: gateway_response,
        status: :pending
      )

      payment
    end

    private

    def find_or_create_payment
      payment = @order.payment

      raise StandardError, "Order is already paid" if payment&.successful?

      payment || Payment.create!(
        order: @order,
        gateway: @gateway,
        amount: @order.total,
        currency: "INR",
        status: :pending
      )
    end

    def gateway_service
      Payments::Providers::Factory.for(@gateway)
    end
  end
end
