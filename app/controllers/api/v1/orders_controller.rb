module Api
  module V1
    class OrdersController < BaseController
      before_action :authenticate_user!
      before_action :set_order, only: %i[show update tracking]

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

      def update
        ::Orders::UpdateStatus.new(@order, params.require(:status)).call

        render json: @order.as_json(
          include: {
            order_items: {},
            payment: {}
          }
        )
      rescue ::Orders::Errors::InvalidStatus, Deliveries::Providers::Borzo::Client::Error, ActionController::ParameterMissing => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      def tracking
        result = Deliveries::RefreshTracking.new(@order).call
        body = Deliveries::TrackingPayload.for(result.order)
        body[:error] = result.error if result.error.present?
        render json: body, status: result.http_status
      end

      private

      def set_order
        @order = current_user.orders.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Order not found" }, status: :not_found
      end
    end
  end
end
