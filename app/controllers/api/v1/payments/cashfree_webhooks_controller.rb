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
        rescue JSON::ParserError
          render json: { error: "Invalid JSON payload" }, status: :bad_request
        rescue ActiveRecord::RecordNotFound
          render json: { error: "Payment not found" }, status: :not_found
        rescue StandardError => e
          Rails.logger.error(
            "Cashfree webhook failed: #{e.class} - #{e.message}"
          )

          render json: { error: e.message }, status: :unprocessable_entity
        end
      end
    end
  end
end
