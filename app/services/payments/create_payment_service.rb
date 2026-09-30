module Payments
  class CreatePaymentService
    def initialize(order, gateway: "cashfree")
      @order = order
      @gateway = gateway.to_s
    end

    def call
      provider = gateway_service # fail fast on unknown gateways, before touching the DB

      payment = @order.with_lock do
        ensure_payable!
        find_or_create_payment
      end

      # A retry of an in-progress checkout already has a session. Reusing it
      # avoids a second Cashfree order for the same checkout.
      return payment.reload if payment.payment_session_id.present?

      gateway_response = provider.new(@order).call
      store_gateway_response(payment, gateway_response)

      payment
    end

    private

    def ensure_payable!
      if @order.payment&.successful?
        raise Errors::OrderNotPayable, "Order is already paid"
      end

      if @order.completed? || @order.cancelled?
        raise Errors::OrderNotPayable, "Order is #{@order.status} and cannot accept a payment"
      end
    end

    def find_or_create_payment
      @order.payment || Payment.create!(
        order: @order,
        gateway: @gateway,
        amount: @order.total,
        currency: "INR",
        status: :pending
      )
    end

    # The gateway call sits outside the lock. A webhook can finalize the
    # payment in that window, so this write must not move a successful payment
    # back to pending.
    def store_gateway_response(payment, response)
      @order.with_lock do
        payment.lock!

        next if payment.successful?

        payment.update!(
          gateway_order_id: response["order_id"],
          payment_session_id: response["payment_session_id"],
          metadata: payment.metadata.merge(response),
          status: :pending
        )
      end
    end

    def gateway_service
      Payments::Providers::Factory.for(@gateway)
    end
  end
end
