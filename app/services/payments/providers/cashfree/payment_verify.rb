require "openssl"
require "base64"
require "json"

module Payments
  module Providers
    module Cashfree
      # Verifies a Cashfree payment webhook. A finished payment (success or
      # failure) creates the order from the checkout snapshot. Success also
      # soft-deletes the cart. Safe to call multiple times for the same event:
      # Cashfree retries webhooks, so all state checks happen under a row lock.
      class PaymentVerify
        GATEWAY = "cashfree".freeze
        # Cashfree payment_status values, mapped onto Payment#status.
        # Finished payments create an order. A successful payment is never moved again.
        STATUS_FOR = {
          "SUCCESS" => :successful,
          "FAILED" => :failed,
          "USER_DROPPED" => :failed,
          "CANCELLED" => :cancelled,
          "VOID" => :cancelled,
          "PENDING" => :pending,
          "NOT_ATTEMPTED" => :pending
        }.freeze

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

          # Lock the cart first, then the payment. CreatePaymentService uses the
          # same cart -> payment sequence, which avoids deadlocks between a
          # checkout retry and an in-flight webhook.
          payment.cart.with_lock do
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

          target = STATUS_FOR[payment_status]
          if target.nil?
            log_ignored(payment, payment_status, "unhandled payment_status")
            return
          end

          if target == :successful
            # A SUCCESS may arrive after FAILED/USER_DROPPED on the same gateway
            # order. The customer has been charged and must get their order.
            mark_successful(payment, gateway_payment_id, payload)
            return
          end

          # Pending must not reopen a failed or cancelled checkout.
          if target == :pending && !payment.pending? && !payment.processing?
            log_ignored(payment, payment_status, "payment already #{payment.status}")
            return
          end

          if %i[failed cancelled].include?(target)
            if payment.status == target.to_s && payment.order.present?
              log_ignored(payment, payment_status, "payment already #{payment.status}")
              return
            end

            mark_unpaid(payment, target, gateway_payment_id, payment_status, payload)
            return
          end

          update_status(payment, target, gateway_payment_id, payment_status, payload)
        end

        def mark_successful(payment, gateway_payment_id, payload)
          order = Orders::CreateOrderService.new(payment, status: :confirmed).call

          payment.update!(
            order: order,
            gateway_payment_id: gateway_payment_id,
            status: :successful,
            metadata: payment.metadata.merge("webhook" => payload)
          )
        end

        def mark_unpaid(payment, status, gateway_payment_id, payment_status, payload)
          order = Orders::CreateOrderService.new(payment, status: :cancelled).call
          metadata = payment.metadata.merge(
            "webhook" => payload,
            "final_payment_status" => payment_status
          )
          attributes = { order: order, status: status, metadata: metadata }
          attributes[:gateway_payment_id] = gateway_payment_id if gateway_payment_id.present?

          payment.update!(attributes)
        end

        def update_status(payment, status, gateway_payment_id, payment_status, payload)
          metadata = payment.metadata.merge("webhook" => payload)
          metadata["final_payment_status"] = payment_status unless status == :pending

          attributes = { status: status, metadata: metadata }
          attributes[:gateway_payment_id] = gateway_payment_id if gateway_payment_id.present?

          payment.update!(attributes)
        end

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
          return if payment.order.blank? || payment.order.delivery_address.blank?
          return if payment.order.delivery.present?

          Deliveries::PlaceDeliveryService.new(payment.order).call
        end
      end
    end
  end
end
