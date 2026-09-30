module Orders
  class CreateOrderService
    def initialize(user, cart_id)
      @user = user
      @cart_id = cart_id
    end

    # Returns the open order for this cart. A second checkout while that order
    # is still open returns the same row instead of creating another one.
    def call
      cart = @user.carts.find(@cart_id)

      # Lock the cart for the whole snapshot. Cart item writes take the same
      # lock, so quantities cannot change between the read and the insert.
      cart.with_lock do
        raise ActiveRecord::RecordNotFound unless cart.live?

        cart.orders.active.order(created_at: :desc).first || create_order(cart)
      end
    end

    private

    def create_order(cart)
      cart_items = cart.cart_items.includes(:menu_item).to_a
      raise CartEmpty, "Cart is empty" if cart_items.empty?

      subtotal = cart_items.sum { |item| item.quantity * item.unit_price }

      order = @user.orders.create!(
        cart: cart,
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

      order
    end
  end
end
