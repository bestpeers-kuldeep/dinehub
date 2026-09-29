module Api
  module V1
    class CartItemsController < BaseController
      before_action :authenticate_user!
      before_action :set_cart_item, only: %i[update destroy]

      def create
        cart_item = ::CartItems::AddToCart.call(current_user, cart_item_params)

        render json: cart_item, status: :created
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Menu item not found" }, status: :not_found
      end

      def update
        if @cart_item.update(quantity: cart_item_params[:quantity])
          render json: @cart_item
        else
          render_errors(@cart_item)
        end
      end

      def destroy
        @cart_item.destroy
        render json: { message: "Item removed from cart" }
      end

      private

      def set_cart_item
        cart = current_user.carts.active.first
        @cart_item = cart&.cart_items&.find(params[:id])

        return if @cart_item

        render json: { error: "Cart item not found" }, status: :not_found
      end

      def cart_item_params
        params.require(:cart_item).permit(:menu_item_id, :quantity)
      end

      def render_errors(record)
        render json: { errors: record.errors.full_messages },
               status: :unprocessable_entity
      end
    end
  end
end
