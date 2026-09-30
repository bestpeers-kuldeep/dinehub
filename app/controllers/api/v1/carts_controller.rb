module Api
  module V1
    class CartsController < BaseController
      before_action :authenticate_user!

      def show
        cart = current_user.carts.active.first || current_user.carts.create

        render json: cart.as_json(
          include: {
            cart_items: {
              include: :menu_item
            }
          }
        )
      end

      def destroy
        cart = current_user.carts.active.first

        return render json: { message: "Cart is already empty" } unless cart

        cart.with_lock do
          if cart.orders.active.exists?
            raise ::Orders::Errors::CartNotEditable, "Cart is checked out and cannot be cleared"
          end

          cart.update!(deleted_at: Time.current)
        end

        render json: { message: "Cart cleared successfully" }
      rescue ::Orders::Errors::CartNotEditable => e
        render json: { error: e.message }, status: :unprocessable_entity
      end
    end
  end
end
