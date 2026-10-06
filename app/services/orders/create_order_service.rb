module Orders
  # Builds the order from the checkout snapshot once Cashfree reports a
  # finished payment. Success confirms the order and soft-deletes the cart.
  # Failure records a cancelled order and leaves the cart so the customer
  # can pay again.
  class CreateOrderService
    def initialize(payment, status:)
      @payment = payment
      @status = status.to_sym
    end

    def call
      order = @payment.order || create_order
      order.update!(status: @status) if order.status != @status.to_s
      clear_cart(@payment.cart) if @status == :confirmed
      order
    end

    private

    def create_order
      checkout = @payment.metadata.fetch("checkout")
      cart = @payment.cart

      order = cart.user.orders.create!(
        cart: cart,
        delivery_address: @payment.delivery_address,
        status: @status,
        subtotal: checkout.fetch("subtotal"),
        tax: checkout.fetch("tax"),
        total: checkout.fetch("total")
      )

      Array(checkout.fetch("items")).each do |item|
        quantity = item.fetch("quantity").to_i
        unit_price = item.fetch("unit_price").to_d

        order.order_items.create!(
          menu_item_id: item.fetch("menu_item_id"),
          name: item.fetch("name"),
          quantity: quantity,
          unit_price: unit_price,
          total_price: quantity * unit_price
        )
      end

      order
    end

    def clear_cart(cart)
      return if cart.deleted_at.present?

      cart.update!(status: :completed, deleted_at: Time.current)
    end
  end
end
