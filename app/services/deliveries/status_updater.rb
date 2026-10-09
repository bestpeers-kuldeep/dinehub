
module Deliveries
  class StatusUpdater
    def initialize(delivery:, payload:, external_event_id:)
      @delivery = delivery
      @payload = payload
      @external_event_id = external_event_id
    end

    def call
      provider_delivery = @payload.fetch("delivery", {})
      event_type = @payload["event_type"].presence || "delivery_updated"

      Delivery.transaction do
        event = @delivery.delivery_events.create_or_find_by!(
          external_event_id: @external_event_id
        ) do |record|
          record.event_type = event_type
          record.payload = @payload
        end

        next @delivery if event.persisted? && !event.previously_new_record?

        status = Providers::Factory
        .status_mapper_for(@delivery.provider)
        .call(
          provider_delivery["status"].presence ||
          provider_delivery["status_description"]
        )

        attributes = {
          tracking_url: provider_delivery["tracking_url"],
          metadata: @delivery.metadata.to_h.merge("latest_callback" => @payload)
        }.compact

        courier = provider_delivery["courier"] || {}

        attributes[:rider_name] = [
          courier["name"],
          courier["surname"]
        ].compact_blank.join(" ").presence

        attributes[:rider_phone] = courier["phone"]
        attributes[:rider_latitude] = courier["latitude"]
        attributes[:rider_longitude] = courier["longitude"]

        attributes[:status] = status if status.present?

        @delivery.update!(attributes.compact)
      end

      @delivery
    end
  end
end
