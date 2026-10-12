module Deliveries
  class RefreshTracking
    class NotPlaced < StandardError; end

    Result = Struct.new(:order, :error, :http_status, keyword_init: true)

    def initialize(order)
      @order = order
    end

    def call
      delivery = @order.delivery
      raise NotPlaced, "This order has no Borzo delivery yet" if delivery&.external_order_id.blank?

      borzo_order = Providers::Borzo::FetchOrder.new(delivery).call
      courier = Providers::Borzo::FetchCourier.new(delivery).call
      payload = {
        "event_type" => "tracking_refresh",
        "order" => borzo_order.merge("courier" => courier).compact
      }

      StatusUpdater.new(
        delivery: delivery,
        payload: payload,
        external_event_id: "track-#{delivery.external_order_id}-#{SecureRandom.uuid}"
      ).call

      Result.new(order: @order.reload, http_status: :ok)
    rescue NotPlaced => e
      Result.new(order: @order, error: e.message, http_status: :unprocessable_entity)
    rescue Providers::Borzo::Client::Error => e
      Result.new(order: @order, error: e.message, http_status: :bad_gateway)
    end
  end
end
