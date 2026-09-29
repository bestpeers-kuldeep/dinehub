module Orders
  class CreateOrderService
    def initialize(user)
      @user = user
    end

    def call
      cart = @user.carts.active.first
      cart_items = cart&.cart_items&.includes(:menu_item)

      raise StandardError, "Cart is empty" if cart_items.blank?

      Order.transaction do
        subtotal = calculate_subtotal(cart_items)

        order = @user.orders.create!(
          status: :pending,
          subtotal: subtotal,
          tax: 0,
          total: subtotal
        )

        create_order_items(order, cart_items)
        cart.update!(status: :completed)

        order
      end
    end

    private

    def calculate_subtotal(cart_items)
      cart_items.sum do |item|
        item.quantity * item.unit_price
      end
    end

    def create_order_items(order, cart_items)
      cart_items.each do |cart_item|
        order.order_items.create!(
          menu_item: cart_item.menu_item,
          name: cart_item.menu_item.name,
          quantity: cart_item.quantity,
          unit_price: cart_item.unit_price,
          total_price: cart_item.quantity * cart_item.unit_price
        )
      end
    end
  end
end
