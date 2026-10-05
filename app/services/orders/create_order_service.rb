module Orders
  class CreateOrderService
    def initialize(user, cart_id, delivery_address_id)
      @user = user
      @cart_id = cart_id
      @delivery_address_id = delivery_address_id
    end

    def call
      cart = @user.carts.find(@cart_id)

      cart.with_lock do
        raise ActiveRecord::RecordNotFound unless cart.live?

        cart.orders.active.order(created_at: :desc).first || create_order(cart)
      end
    end

    private

    def create_order(cart)
      cart_items = cart.cart_items.includes(:menu_item).to_a
      raise Errors::CartEmpty, "Cart is empty" if cart_items.empty?

      delivery_address = @user.delivery_addresses.find(@delivery_address_id)

      subtotal = cart_items.sum { |item| item.quantity * item.unit_price }

      order = @user.orders.create!(
        cart: cart,
        delivery_address: delivery_address,
        status: :pending,
        subtotal: subtotal,
        tax: 0,
        total: subtotal
      )

      cart_items.each do |cart_item|
        order.order_items.create!(
          menu_item: cart_item.menu_item,
          name: cart_item.menu_item.name,
          quantity: cart_item.quantity,
          unit_price: cart_item.unit_price,
          total_price: cart_item.quantity * cart_item.unit_price
        )
      end

      cart.update!(status: :completed)

      order
    end
  end
end
