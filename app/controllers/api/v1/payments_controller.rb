module Api
  module V1
    class PaymentsController < BaseController
      before_action :authenticate_user!
      before_action :set_order

      def create
        payment = ::Payments::CreatePaymentService.new(@order).call

        render json: {
          order_id: @order.id,
          payment: payment_response(payment)
        }, status: :ok
      rescue StandardError => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      private

      def set_order
        @order = current_user.orders.find(params[:order_id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Order not found" }, status: :not_found
      end

      def payment_response(payment)
        {
          id: payment.id,
          gateway: payment.gateway,
          amount: payment.amount,
          currency: payment.currency,
          status: payment.status,
          payment_session_id: payment.payment_session_id
        }
      end
    end
  end
end
