module Deliveries
  module Providers
    module Borzo
      class FetchOrder
        def initialize(delivery)
          @delivery = delivery
        end

        def call
          body = Client.new.get("orders", order_id: @delivery.external_order_id)
          order = Array(body["orders"]).first
          raise Client::Error, "Borzo order not found" if order.blank?

          order
        end
      end
    end
  end
end
