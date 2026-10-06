module Api
  module V1
    class PaymentsController < BaseController
      before_action :authenticate_user!, except: :payment_return

      def create
        payment = ::Payments::CreatePaymentService.new(
          current_user,
          cart_id: payment_params[:cart_id],
          delivery_address_id: payment_params[:delivery_address_id]
        ).call

        render json: { payment: payment_response(payment) }, status: :ok
      rescue ::Payments::Errors::Gateway => e
        Rails.logger.error("Payment gateway error: #{e.message}")

        render json: { error: "Payment gateway is unavailable, please try again" }, status: :bad_gateway
      rescue ::Payments::Errors::CheckoutInProgress, ::Orders::Errors::CartEmpty => e
        render json: { error: e.message }, status: :unprocessable_entity
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Cart or delivery address not found" }, status: :not_found
      end

      def payment_return
        payment = Payment.find_by(gateway: "cashfree", gateway_order_id: params[:order_id])

        render json: {
          message: payment&.order ? "Payment flow completed" : "Payment is processing",
          order_id: payment&.order_id,
          gateway_order_id: params[:order_id]
        }
      end

      private

      def payment_params
        params.permit(:cart_id, :delivery_address_id)
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
