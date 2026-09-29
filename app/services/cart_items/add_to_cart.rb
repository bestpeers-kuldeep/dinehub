module CartItems
  class AddToCart
    def self.call(user, params)
      new(user, params).call
    end

    def initialize(user, params)
      @user = user
      @params = params
    end

    def call
      cart = @user.carts.active.first || @user.carts.create!

      CartItem.transaction do
        @params.map do |item_params|
          add_item(cart, item_params)
        end
      end
    end

    private

    def add_item(cart, item_params)
      cart_item = cart.cart_items.find_or_initialize_by(
        menu_item_id: item_params[:menu_item_id]
      )

      if cart_item.persisted?
        cart_item.quantity += item_params[:quantity].to_i
      else
        menu_item = MenuItem.find(item_params[:menu_item_id])

        cart_item.assign_attributes(
          quantity: item_params[:quantity],
          unit_price: menu_item.price
        )
      end

      cart_item.save!
      cart_item
    end
  end
end
