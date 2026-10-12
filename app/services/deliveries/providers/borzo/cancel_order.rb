module Deliveries
  module Providers
    module Borzo
      class CancelOrder
        def initialize(delivery)
          @delivery = delivery
        end

        def call
          Client.new.post("cancel-order", { order_id: @delivery.external_order_id.to_i })
        end
      end
    end
  end
end
