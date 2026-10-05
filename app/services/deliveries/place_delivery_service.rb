module Deliveries
  class PlaceDeliveryService
    def initialize(order)
      @order = order
    end

    def call
      delivery = @order.delivery || @order.build_delivery(
        provider: "borzo",
        status: :pending
      )

      delivery.save!

      response = Providers::Factory
        .for(delivery.provider)
        .new(delivery)
        .call

      update_delivery(delivery, response)

      delivery
    end

    private

    def update_delivery(delivery, response)
      delivery.update!(
        external_order_id: response["order_id"],
        external_delivery_id: response.dig("points", 1, "delivery_id"),
        tracking_url: response.dig("points", 1, "tracking_url"),
        status: :requested,
        metadata: response
      )
    end
  end
end
