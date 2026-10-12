require "net/http"
require "json"

module Deliveries
  module Providers
    module Borzo
      class Client
        class Error < StandardError; end

        def initialize
          @base_url = ENV.fetch("BORZO_BASE_URL")
          @token = ENV.fetch("BORZO_API_TOKEN")
        end

        def get(path, params = {})
          perform(Net::HTTP::Get, path, params: params)
        end

        def post(path, payload)
          perform(Net::HTTP::Post, path, payload: payload)
        end

        private

        def perform(request_class, path, params: nil, payload: nil)
          uri = URI.join("#{@base_url}/", path)
          uri.query = URI.encode_www_form(params) if params.present?

          request = request_class.new(uri)
          request["X-DV-Auth-Token"] = @token
          request["Content-Type"] = "application/json"
          request.body = JSON.generate(payload) if payload

          response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") do |http|
            http.request(request)
          end

          Rails.logger.info("BORZO STATUS: #{response.code}")
          Rails.logger.info("BORZO RESPONSE: #{response.body}")

          body = JSON.parse(response.body)
          return body if response.is_a?(Net::HTTPSuccess) && body["is_successful"]

          raise Error, error_message(body)
        rescue JSON::ParserError
          raise Error, "Borzo API returned invalid JSON"
        end

        def error_message(body)
          errors = body["errors"]
          case errors
          when Array
            errors.map { |error| error.is_a?(Hash) ? error["message"] || error.to_s : error.to_s }.join(", ")
          when String
            errors
          else
            "Borzo API request failed"
          end
        end
      end
    end
  end
end
