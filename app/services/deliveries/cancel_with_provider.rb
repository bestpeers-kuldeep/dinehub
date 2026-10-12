module Deliveries
  # Borzo only lets the merchant cancel an open order. Kitchen statuses stay local.
  class CancelWithProvider
    def initialize(order)
      @order = order
    end

    def call
      delivery = @order.delivery
      return if delivery.blank? || delivery.external_order_id.blank?
      return if delivery.cancelled? || delivery.delivered? || delivery.failed?

      response = Providers::Borzo::CancelOrder.new(delivery).call
      delivery.update!(
        status: :cancelled,
        metadata: delivery.metadata.to_h.merge("cancel_response" => response["order"])
      )
    end
  end
end
