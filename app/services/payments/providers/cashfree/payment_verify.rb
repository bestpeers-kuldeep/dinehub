require "openssl"
require "base64"
require "json"

module Payments
  module Providers
    module Cashfree
      # Verifies a Cashfree payment webhook and moves the payment/order to a
      # terminal state. Safe to call multiple times for the same event:
      # Cashfree retries webhooks, so all state checks happen under a row lock.
      class PaymentVerify
        GATEWAY = "cashfree".freeze
        SUCCESS_STATUSES = %w[SUCCESS].freeze
        FAILURE_STATUSES = %w[FAILED USER_DROPPED].freeze

        def initialize(raw_body:, signature:, timestamp:)
          @raw_body = raw_body.to_s
          @signature = signature
          @timestamp = timestamp
        end

        def call
          verify_signature!

          payload = parse_payload
          payment_status = payload.dig("data", "payment", "payment_status")
          gateway_payment_id = payload.dig("data", "payment", "cf_payment_id")
          gateway_order_id = payload.dig("data", "order", "order_id")

          if gateway_order_id.blank?
            raise Errors::InvalidPayload, "Webhook payload is missing data.order.order_id"
          end

          payment = Payment.find_by!(gateway: GATEWAY, gateway_order_id: gateway_order_id)

          # Lock order first, then payment. CreatePaymentService uses the same
          # order -> payment locking sequence, which avoids deadlocks between a
          # checkout retry and an in-flight webhook.
          payment.order.with_lock do
            payment.lock!

            apply_transition(payment, payment_status, gateway_payment_id, payload)
          end

          trigger_delivery_if_required(payment)
          payment
        end

        private

        def apply_transition(payment, payment_status, gateway_payment_id, payload)
          # A successful payment is final; nothing can override it.
          if payment.successful?
            log_ignored(payment, payment_status, "payment already successful")
            return
          end

          case payment_status
          when *SUCCESS_STATUSES
            # A SUCCESS may legitimately arrive after a FAILED/USER_DROPPED for
            # an earlier attempt on the same gateway order, so failed -> successful
            # is allowed; the customer has been charged and must get their order.
            mark_successful(payment, gateway_payment_id, payload)
          when *FAILURE_STATUSES
            if payment.failed?
              log_ignored(payment, payment_status, "payment already failed")
            else
              mark_failed(payment, gateway_payment_id, payment_status, payload)
            end
          else
            log_ignored(payment, payment_status, "unhandled payment_status")
          end
        end

        def mark_successful(payment, gateway_payment_id, payload)
          payment.update!(
            gateway_payment_id: gateway_payment_id,
            status: :successful,
            metadata: payment.metadata.merge("webhook" => payload)
          )

          payment.order.update!(status: :completed)
        end

        def mark_failed(payment, gateway_payment_id, payment_status, payload)
          payment.update!(
            gateway_payment_id: gateway_payment_id,
            status: :failed,
            metadata: payment.metadata.merge(
              "webhook" => payload,
              "final_payment_status" => payment_status
            )
          )

          payment.order.update!(status: :cancelled)

          # The cart is deliberately left untouched on failure so the customer
          # can retry checkout without rebuilding it.
        end

        # Marks the cart that produced this order as consumed. Uses the order's
        # own cart rather than "any live cart for the user" so a cart the user
        # started after checkout is never wiped by a late webhook.

        def log_ignored(payment, payment_status, reason)
          Rails.logger.info(
            "Cashfree webhook ignored: payment_id=#{payment.id} " \
            "payment_status=#{payment_status.inspect} reason=#{reason}"
          )
        end

        def parse_payload
          payload = JSON.parse(@raw_body)

          unless payload.is_a?(Hash)
            raise Errors::InvalidPayload, "Webhook payload must be a JSON object"
          end

          payload
        rescue JSON::ParserError => e
          raise Errors::InvalidPayload, "Invalid JSON payload: #{e.message}"
        end

        def verify_signature!
          raise Errors::Signature, "Missing Cashfree webhook signature" if @signature.blank?
          raise Errors::Signature, "Missing Cashfree webhook timestamp" if @timestamp.blank?

          expected_signature = Base64.strict_encode64(
            OpenSSL::HMAC.digest("SHA256", secret_key, "#{@timestamp}#{@raw_body}")
          )

          return if ActiveSupport::SecurityUtils.secure_compare(expected_signature, @signature)

          raise Errors::Signature, "Invalid Cashfree webhook signature"
        end

        def secret_key
          ENV.fetch("CASHFREE_SECRET_KEY")
        end

        def trigger_delivery_if_required(payment)
          return unless payment.successful?
          return if payment.order.delivery.present?

          Deliveries::PlaceDeliveryService.new(payment.order).call
        end
      end
    end
  end
end
