module Api
  module V1
    class CartItemsController < BaseController
      before_action :authenticate_user!
      before_action :set_cart_item, only: %i[update destroy]

      def create
        cart_items = ::CartItems::AddToCart.call(
          current_user,
          cart_item_params
        )

        render json: cart_items, status: :created
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Menu item not found" }, status: :not_found
      end

      def update
        if @cart_item.update(quantity: update_cart_item_params[:quantity])
          render json: @cart_item
        else
          render_errors(@cart_item)
        end
      end

      def destroy
        @cart_item.destroy!

        render json: { message: "Item removed from cart" }, status: :ok
      rescue => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      private

      def update_cart_item_params
        params.require(:cart_item).permit(:quantity)
      end

      def set_cart_item
        cart = current_user.carts.active.first

        unless cart
          render json: { error: "Active cart not found" }, status: :not_found
          return
        end

        @cart_item = cart.cart_items.find_by(id: params[:id])

        unless @cart_item
          render json: { error: "Cart item not found" }, status: :not_found
          nil
        end
      end

      def cart_item_params
        params.require(:cart_items).map do |item|
          item.permit(:menu_item_id, :quantity)
        end
      end

      def render_errors(record)
        render json: { errors: record.errors.full_messages },
               status: :unprocessable_entity
      end
    end
  end
end
