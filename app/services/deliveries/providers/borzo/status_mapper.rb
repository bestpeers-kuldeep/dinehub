
module Deliveries
  module Providers
    module Borzo
      class StatusMapper
        STATUS_MAP = {
          "invalid" => :failed,
          "draft" => :pending,
          "new" => :requested,
          "available" => :requested,
          "planned" => :requested,
          "reactivated" => :requested,
          "active" => :out_for_delivery,
          "courier_assigned" => :assigned,
          "courier_departed" => :assigned,
          "courier_at_pickup" => :assigned,
          "parcel_picked_up" => :picked_up,
          "courier_arrived" => :out_for_delivery,
          "finished" => :delivered,
          "completed" => :delivered,
          "canceled" => :cancelled,
          "deleted" => :cancelled,
          "delayed" => :out_for_delivery,
          "return_planned" => :out_for_delivery,
          "return_courier_assigned" => :assigned,
          "return_courier_departed" => :out_for_delivery,
          "return_courier_picked_up" => :picked_up,
          "return_finished" => :failed,
          "reattempt_planned" => :requested,
          "reattempt_courier_assigned" => :assigned,
          "reattempt_courier_departed" => :out_for_delivery,
          "reattempt_courier_picked_up" => :picked_up,
          "reattempt_finished" => :delivered
        }.freeze

        def self.call(value)
          STATUS_MAP[value.to_s.downcase]
        end
      end
    end
  end
end
