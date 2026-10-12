module Deliveries
  class StatusUpdater
    def initialize(delivery:, payload:, external_event_id:)
      @delivery = delivery
      @payload = payload
      @external_event_id = external_event_id
    end

    def call
      Delivery.transaction do
        event = @delivery.delivery_events.create_or_find_by!(
          external_event_id: @external_event_id
        ) do |record|
          record.event_type = @payload["event_type"].presence || "delivery_updated"
          record.payload = @payload
        end

        next @delivery if event.persisted? && !event.previously_new_record?

        apply_attributes
        SyncOrderStatus.new(@delivery).call
      end

      @delivery.reload
    end

    private

    def source
      @source ||= if @payload["delivery"].is_a?(Hash)
        delivery_source(@payload["delivery"])
      elsif @payload["order"].is_a?(Hash)
        order_source(@payload["order"])
      else
        {}
      end
    end

    def delivery_source(delivery)
      {
        status: delivery["status"].presence || delivery["status_description"],
        tracking_url: delivery["tracking_url"],
        courier: delivery["courier"] || {},
        external_order_id: delivery["order_id"],
        external_delivery_id: delivery["delivery_id"]
      }
    end

    def order_source(order)
      point = Array(order["points"]).reverse.find { |row| row["delivery_id"].present? } || {}
      nested = point["delivery"].is_a?(Hash) ? point["delivery"] : {}

      {
        status: nested["status"].presence || order["status"],
        tracking_url: nested["tracking_url"].presence || point["tracking_url"],
        courier: order["courier"].presence || nested["courier"] || point["courier"] || {},
        external_order_id: order["order_id"],
        external_delivery_id: point["delivery_id"]
      }
    end

    def apply_attributes
      status = Providers::Factory.status_mapper_for(@delivery.provider).call(source[:status])
      courier = source[:courier] || {}

      attributes = {
        tracking_url: source[:tracking_url],
        external_order_id: source[:external_order_id]&.to_s.presence,
        external_delivery_id: source[:external_delivery_id]&.to_s.presence,
        metadata: @delivery.metadata.to_h.merge("latest_callback" => @payload),
        rider_name: [ courier["name"], courier["surname"] ].compact_blank.join(" ").presence,
        rider_phone: courier["phone"],
        rider_latitude: courier["latitude"],
        rider_longitude: courier["longitude"]
      }
      attributes[:status] = forward_status(status) if status.present?

      @delivery.update!(attributes.compact)
    end

    # A late callback must not move a delivery backward, and a finished
    # delivery stays finished. Cancellation can still stop an open delivery.
    def forward_status(incoming)
      current = @delivery.status
      return current if current == "delivered"
      return incoming if %i[cancelled failed].include?(incoming)
      return current if @delivery.cancelled? || @delivery.failed?

      incoming_rank = Delivery.statuses.fetch(incoming.to_s)
      current_rank = Delivery.statuses.fetch(current)
      incoming_rank >= current_rank ? incoming : current
    end
  end
end
