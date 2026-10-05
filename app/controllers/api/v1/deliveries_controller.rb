module Api
  module V1
    class DeliveriesController < BaseController
      before_action :authenticate_user!
      before_action :set_order

      def show
        render json: @order.delivery
      end

      private

      def set_order
        @order = current_user.orders.find(params[:order_id])
      end
    end
  end
end
