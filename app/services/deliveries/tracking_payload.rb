module Deliveries
  class TrackingPayload
    def self.for(order)
      delivery = order.delivery
      {
        order_id: order.id,
        order_status: order.status,
        delivery: delivery&.as_json(only: %i[
          id status provider tracking_url external_order_id external_delivery_id
          rider_name rider_phone rider_latitude rider_longitude
        ])
      }
    end
  end
end
