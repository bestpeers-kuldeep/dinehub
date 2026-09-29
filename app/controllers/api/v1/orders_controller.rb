module Api
  module V1
    class OrdersController < BaseController
      before_action :authenticate_user!
      before_action :set_order, only: %i[show]

      def index
        orders = current_user.orders
                            .includes(:order_items, :payment)
                            .order(created_at: :desc)

        render json: orders.as_json(
          include: {
            order_items: {},
            payment: {}
          }
        )
      end

      def show
        render json: @order.as_json(
          include: {
            order_items: {},
            payment: {}
          }
        )
      end

      def create
        order = ::Orders::CreateOrderService.new(
          current_user,
          order_params[:cart_id]
        ).call

        render json: {
          order: order.as_json(
            include: :order_items
          )
        }, status: :created
      rescue StandardError => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      private

      def order_params
        params.permit(:cart_id)
      end

      def set_order
        @order = current_user.orders.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Order not found" }, status: :not_found
      end
    end
  end
end
