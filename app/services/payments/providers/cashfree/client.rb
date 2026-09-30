require "net/http"
require "json"

module Payments
  module Providers
    module Cashfree
      # Thin Cashfree PG HTTP client. Knows nothing about our orders; CreateOrder
      # decides what to send and how to recover from "order already exists".
      class Client
        API_VERSION = "2025-01-01".freeze
        OPEN_TIMEOUT_SECONDS = 5
        READ_TIMEOUT_SECONDS = 15

        Result = Struct.new(:code, :body, keyword_init: true) do
          def success?
            code.to_i.between?(200, 299)
          end
        end

        def post_order(payload)
          request(Net::HTTP::Post, orders_uri, payload)
        end

        def get_order(order_id)
          uri = orders_uri.dup
          uri.path = "#{uri.path.chomp("/")}/#{URI.encode_uri_component(order_id)}"
          request(Net::HTTP::Get, uri, nil)
        end

        private

        def request(request_class, uri, payload)
          response = Net::HTTP.start(
            uri.hostname,
            uri.port,
            use_ssl: uri.scheme == "https",
            open_timeout: OPEN_TIMEOUT_SECONDS,
            read_timeout: READ_TIMEOUT_SECONDS
          ) do |http|
            http.request(build_request(request_class, uri, payload))
          end

          Result.new(code: response.code.to_i, body: parse_json(response.body))
        rescue Net::OpenTimeout, Net::ReadTimeout, SocketError, SystemCallError, OpenSSL::SSL::SSLError => e
          raise Errors::Gateway, "Cashfree request failed: #{e.class}"
        end

        def build_request(request_class, uri, payload)
          request = request_class.new(uri)
          request["x-client-id"] = ENV.fetch("CASHFREE_APP_ID")
          request["x-client-secret"] = ENV.fetch("CASHFREE_SECRET_KEY")
          request["x-api-version"] = API_VERSION
          request["Accept"] = "application/json"

          if payload
            request["Content-Type"] = "application/json"
            request.body = payload.to_json
          end

          request
        end

        def parse_json(raw)
          parsed = JSON.parse(raw.to_s.presence || "{}")
          parsed.is_a?(Hash) ? parsed : {}
        rescue JSON::ParserError
          {}
        end

        # Fetched per request so the app can boot without this variable set.
        def orders_uri
          URI(ENV.fetch("API_URL"))
        end
      end
    end
  end
end
