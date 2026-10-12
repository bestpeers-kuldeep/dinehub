module Deliveries
  module Providers
    module Borzo
      class FetchCourier
        def initialize(delivery)
          @delivery = delivery
        end

        # Courier location exists only while the Borzo order is active.
        def call
          body = Client.new.get("courier", order_id: @delivery.external_order_id)
          body["courier"]
        rescue Client::Error
          nil
        end
      end
    end
  end
end
