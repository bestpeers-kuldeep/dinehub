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

        cart.update!(deleted_at: Time.current)

        render json: { message: "Cart cleared successfully" }
      end
    end
  end
end