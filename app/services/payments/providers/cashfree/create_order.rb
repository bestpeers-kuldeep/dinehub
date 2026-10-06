# app/services/payments/providers/cashfree/create_order.rb

require "net/http"
require "json"

module Payments
  module Providers
    module Cashfree
      class CreateOrder
        API_URL = ENV.fetch("API_URL")
        API_VERSION = "2025-01-01"

        def initialize(payment)
          @payment = payment
        end

        def call
          uri = URI(API_URL)
          user = @payment.cart.user

          request = Net::HTTP::Post.new(uri)
          request["x-client-id"] = ENV.fetch("CASHFREE_APP_ID")
          request["x-client-secret"] = ENV.fetch("CASHFREE_SECRET_KEY")
          request["x-api-version"] = API_VERSION
          request["Content-Type"] = "application/json"
          request["Accept"] = "application/json"

          request.body = {
            order_id: "CHECKOUT_#{@payment.id}",
            order_amount: @payment.amount.to_f,
            order_currency: @payment.currency,
            customer_details: {
              customer_id: user.id.to_s,
              customer_phone: user.phone
            },
            order_meta: {
              return_url: "#{ENV.fetch("APP_URL")}/api/v1/payments/payment_return?order_id={order_id}"
            }
          }.to_json

          response = Net::HTTP.start(
            uri.hostname,
            uri.port,
            use_ssl: true
          ) do |http|
            http.request(request)
          end

          JSON.parse(response.body)
        end
      end
    end
  end
end
