# app/services/cashfree/create_order.rb

require "net/http"
require "json"

module Cashfree
  class CreateOrder
    API_URL = ENV.fetch("API_URL")
    API_VERSION = "2025-01-01"

    def initialize(order)
      @order = order
    end

    def call
      uri = URI(API_URL)

      request = Net::HTTP::Post.new(uri)
      request["x-client-id"] = ENV.fetch("CASHFREE_APP_ID")
      request["x-client-secret"] = ENV.fetch("CASHFREE_SECRET_KEY")
      request["x-api-version"] = API_VERSION
      request["Content-Type"] = "application/json"
      request["Accept"] = "application/json"

      request.body = {
        order_id: "ORDER_#{@order.id}",
        order_amount: @order.total.to_f,
        order_currency: "INR",
        customer_details: {
          customer_id: @order.user_id.to_s,
          customer_phone: @order.user.phone
        },
        order_meta: {
          return_url: "#{ENV.fetch("APP_URL")}/orders/#{@order.id}/payment_return?order_id={order_id}"
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
