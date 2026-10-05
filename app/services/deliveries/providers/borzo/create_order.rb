module Deliveries
  module Providers
    module Borzo
      class CreateOrder
        def initialize(delivery)
          @delivery = delivery
          @order = delivery.order
        end

        def call
          request_payload = payload

          Rails.logger.info("BORZO PAYLOAD: #{request_payload.inspect}")

          response = Client.new.post(
            "create-order",
            request_payload
          )

          response["order"]
        end

        private

        def payload
          {
            type: "standard",
            matter: "Food",
            vehicle_type_id: 8,
            total_weight_kg: 3,
            insurance_amount: 500.00,
            is_client_notification_enabled: true,
            is_contact_person_notification_enabled: true,
            points: [
              pickup_point,
              delivery_point
            ]
          }
        end

        def pickup_point
          {
            address: ENV.fetch("RESTAURANT_ADDRESS"),
            contact_person: {
              name: ENV.fetch("RESTAURANT_NAME"),
              phone: ENV.fetch("RESTAURANT_PHONE")
            },
            client_order_id: @order.id.to_s
          }
        end

        def delivery_point
          address = @order.delivery_address

          {
            address: [
              address.address_line,
              address.landmark,
              address.city,
              address.state,
              address.postal_code
            ].compact_blank.join(", "),
            contact_person: {
              name: @order.user.full_name,
              phone: @order.user.phone
            },
            latitude: address.latitude,
            longitude: address.longitude,
            client_order_id: @order.id.to_s
          }
        end
      end
    end
  end
end
