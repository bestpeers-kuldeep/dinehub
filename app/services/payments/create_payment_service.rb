module Payments
  # Starts Cashfree checkout from the live cart. No order is created here;
  # the payment webhook inserts the order after the charge succeeds.
  class CreatePaymentService
    def initialize(user, cart_id:, delivery_address_id:, gateway: "cashfree")
      @user = user
      @cart_id = cart_id
      @delivery_address_id = delivery_address_id
      @gateway = gateway.to_s
    end

    def call
      provider = gateway_service # fail fast on unknown gateways, before touching the DB

      cart = @user.carts.find(@cart_id)
      address = @user.delivery_addresses.find(@delivery_address_id)

      payment = cart.with_lock do
        raise ActiveRecord::RecordNotFound unless cart.live?

        ensure_checkout!(cart, address)
      end

      # A retry of the same checkout already has a session. Reusing it avoids a
      # second Cashfree order. ensure_checkout! cancels that session first when
      # the cart total has changed, so this return only applies to an unchanged cart.
      return payment.reload if payment.payment_session_id.present?

      gateway_response = provider.new(payment).call
      store_gateway_response(payment, gateway_response)

      payment.reload
    end

    private

    def ensure_checkout!(cart, address)
      items = cart.cart_items.includes(:menu_item).to_a
      raise Orders::Errors::CartEmpty, "Cart is empty" if items.empty?

      total = Payment.total_for(items)
      raise Orders::Errors::CartEmpty, "Cart total must be greater than 0" unless total.positive?

      payment = cart.payments.open_checkout.first
      if payment&.payment_session_id.present?
        if payment.checkout_current?(items, total)
          if payment.delivery_address_id != address.id
            raise Errors::CheckoutInProgress, "Checkout is already in progress for a different address"
          end

          return payment
        end

        # The session was priced for the previous cart. Cancel it and start
        # a new checkout for the current total.
        payment.abandon_for_cart_change!
        payment = nil
      end

      snapshot = Payment.checkout_snapshot(items, total)
      if payment
        payment.update!(
          delivery_address: address,
          amount: total,
          metadata: payment.metadata.merge("checkout" => snapshot)
        )
        payment
      else
        cart.payments.create!(
          gateway: @gateway,
          amount: total,
          currency: "INR",
          status: :pending,
          delivery_address: address,
          metadata: { "checkout" => snapshot }
        )
      end
    end

    # The gateway call sits outside the lock. A webhook can finalize the
    # payment in that window, so this write must not move a successful payment
    # back to pending or detach the order it just created.
    def store_gateway_response(payment, response)
      payment.cart.with_lock do
        payment.lock!

        next if payment.successful? || payment.order_id.present?

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
