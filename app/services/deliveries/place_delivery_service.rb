
module Deliveries
  class PlaceDeliveryService
    def initialize(order)
      @order = order
    end

    def call
      delivery = find_or_create_delivery

      delivery.with_lock do
        # Do not create another Borzo order if one is already recorded.
        return delivery if delivery.external_order_id.present?

        response = Providers::Factory
          .for(delivery.provider)
          .new(delivery)
          .call

        update_delivery(delivery, response)
      end

      delivery
    end

    private

    def find_or_create_delivery
      Delivery.create_or_find_by!(order_id: @order.id) do |delivery|
        delivery.provider = "borzo"
        delivery.status = :pending
      end
    end

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
