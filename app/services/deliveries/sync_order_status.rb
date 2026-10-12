module Deliveries
  # Moves the kitchen order when Borzo has assigned, picked up, delivered, or cancelled.
  class SyncOrderStatus
    ORDER_STATUS = {
      "assigned" => "ready",
      "picked_up" => "ready",
      "out_for_delivery" => "ready",
      "delivered" => "completed",
      "cancelled" => "cancelled",
      "failed" => "cancelled"
    }.freeze

    def initialize(delivery)
      @delivery = delivery
      @order = delivery.order
    end

    def call
      target = ORDER_STATUS[@delivery.status]
      return @order if target.blank? || @order.status == target
      return @order if @order.completed? || @order.cancelled?

      @order.update!(status: target)
      @order
    end
  end
end
