require "openssl"
require "base64"
require "json"

module Payments
  module Providers
    module Cashfree
      class PaymentVerify
        def initialize(raw_body:, signature:, timestamp:)
          @raw_body = raw_body
          @signature = signature
          @timestamp = timestamp
        end

        def call
          verify_signature!

          payload = JSON.parse(@raw_body)

          payment_data = payload["data"]&.fetch("payment", {})
          order_data = payload["data"]&.fetch("order", {})

          payment_status = payment_data["payment_status"]
          gateway_order_id = order_data["order_id"]
          gateway_payment_id = payment_data["cf_payment_id"]

          payment = Payment.find_by!(
            gateway_order_id: gateway_order_id
          )

          return if terminal_payment?(payment)

          case payment_status
          when "SUCCESS"
            handle_success(payment, gateway_payment_id, payload)
          when "FAILED", "USER_DROPPED"
            handle_failure(payment, gateway_payment_id, payment_status, payload)
          else
            Rails.logger.info(
              "Cashfree webhook ignored: payment_status=#{payment_status}"
            )
          end
        end

        private

        def handle_success(payment, gateway_payment_id, payload)
          payment.order.with_lock do
            payment.update!(
              gateway_payment_id: gateway_payment_id,
              status: :successful,
              metadata: payment.metadata.merge(payload)
            )

            payment.order.update!(
              status: :completed
            )

            soft_delete_cart(payment.order)
          end

          payment
        end

        def handle_failure(payment, gateway_payment_id, payment_status, payload)
          payment.order.with_lock do
            payment.update!(
              gateway_payment_id: gateway_payment_id,
              status: :failed,
              metadata: payment.metadata.merge(
                payload.merge(
                  "final_payment_status" => payment_status
                )
              )
            )

            payment.order.update!(
              status: :cancelled
            )

            soft_delete_cart(payment.order)
          end

          payment
        end

        def terminal_payment?(payment)
          payment.successful? || payment.failed?
        end

        def verify_signature!
          raise "Missing Cashfree webhook signature" if @signature.blank?
          raise "Missing Cashfree webhook timestamp" if @timestamp.blank?

          signed_payload = "#{@timestamp}#{@raw_body}"

          digest = OpenSSL::Digest.new("SHA256")

          generated_signature = Base64.strict_encode64(
            OpenSSL::HMAC.digest(
              digest,
              ENV.fetch("CASHFREE_SECRET_KEY"),
              signed_payload
            )
          )

          return if ActiveSupport::SecurityUtils.secure_compare(
            generated_signature,
            @signature
          )

          raise "Invalid Cashfree webhook signature"
        end

        def soft_delete_cart(order)
          cart = Cart.find_by(
            user_id: order.user_id,
            deleted_at: nil
          )

          return unless cart

          cart.update!(
            status: "completed",
            deleted_at: Time.current
          )
        end
      end
    end
  end
end
