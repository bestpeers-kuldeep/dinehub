module Api
  module V1
    module Payments
      class CashfreeWebhooksController < ActionController::API
        def create
          ::Payments::Providers::Cashfree::PaymentVerify.new(
            raw_body: request.raw_post,
            signature: request.headers["x-webhook-signature"],
            timestamp: request.headers["x-webhook-timestamp"]
          ).call

          render json: { success: true }, status: :ok
        rescue ::Payments::Errors::Signature => e
          Rails.logger.warn("Cashfree webhook rejected: #{e.message}")

          render json: { error: "Invalid webhook signature" }, status: :unauthorized
        rescue ::Payments::Errors::InvalidPayload => e
          render json: { error: e.message }, status: :bad_request
        rescue ActiveRecord::RecordNotFound
          render json: { error: "Payment not found" }, status: :not_found
        end

        # Anything else (DB down, unexpected exception) intentionally propagates
        # as a 500 so Cashfree retries the delivery and the error is reported.
      end
    end
  end
end
