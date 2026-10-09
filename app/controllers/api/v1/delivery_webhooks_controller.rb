
require "openssl"
require "digest"

module Api
  module V1
    class DeliveryWebhooksController < BaseController
      skip_before_action :authenticate_user!, raise: false

      def borzo
        raw_body = request.raw_post

        unless valid_signature?(raw_body)
          return head :unauthorized
        end

        payload = JSON.parse(raw_body)
        provider_delivery = payload["delivery"]

        return head :bad_request unless provider_delivery.is_a?(Hash)

        delivery = find_delivery(provider_delivery)

        # A callback may arrive before the provider IDs have been saved.
        # Ask Borzo to retry rather than acknowledging an unprocessed event.
        return head :service_unavailable unless delivery

        event_id = Digest::SHA256.hexdigest(raw_body)

        Deliveries::StatusUpdater.new(
          delivery: delivery,
          payload: payload,
          external_event_id: event_id
        ).call

        head :ok
      rescue JSON::ParserError
        head :bad_request
      rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique => e
        Rails.logger.error("Borzo callback database error: #{e.message}")
        head :internal_server_error
      end

      private

      def valid_signature?(raw_body)
        secret = ENV["BORZO_CALLBACK_SECRET"].to_s
        signature = request.headers["X-DV-Signature"].to_s

        Rails.logger.info("Borzo signature header present: #{signature.present?}")
        Rails.logger.info("Borzo callback secret present: #{secret.present?}")
        Rails.logger.info("Borzo signature length: #{signature.bytesize}")

        return false if secret.blank? || signature.blank?

        expected = OpenSSL::HMAC.hexdigest("SHA256", secret, raw_body)
                Rails.logger.info(
          "Borzo signature matches: #{ActiveSupport::SecurityUtils.secure_compare(expected, signature)}"
        )
        return false unless signature.bytesize == expected.bytesize
                Rails.logger.info(
          "Borzo signature matches: #{ActiveSupport::SecurityUtils.secure_compare(expected, signature)}"
        )
        ActiveSupport::SecurityUtils.secure_compare(expected, signature)
      end


      def find_delivery(provider_delivery)
        scope = Delivery.where(provider: "borzo")

        delivery = if provider_delivery["delivery_id"].present?
          scope.find_by(external_delivery_id: provider_delivery["delivery_id"].to_s)
        end

        delivery ||= if provider_delivery["order_id"].present?
          scope.find_by(external_order_id: provider_delivery["order_id"].to_s)
        end

        return delivery if delivery

        client_order_id = provider_delivery["client_order_id"]
        return if client_order_id.blank? || !client_order_id.to_s.match?(/\A\d+\z/)

        order = Order.find_by(id: client_order_id.to_i)
        return unless order

        delivery = Delivery.find_or_create_by!(order: order) do |record|
          record.provider = "borzo"
          record.status = :requested
        end

        delivery.with_lock do
          delivery.update!(
            external_order_id: provider_delivery["order_id"].to_s.presence,
            external_delivery_id: provider_delivery["delivery_id"].to_s.presence,
            tracking_url: provider_delivery["tracking_url"].presence
          )
        end

        delivery
      end
    end
  end
end
