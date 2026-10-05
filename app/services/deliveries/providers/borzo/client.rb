require "net/http"
require "json"

module Deliveries
  module Providers
    module Borzo
      class Client
        def initialize
          @base_url = ENV.fetch("BORZO_BASE_URL")
          @token = ENV.fetch("BORZO_API_TOKEN")
        end

        def post(path, payload)
          uri = URI.join("#{@base_url}/", path)

          request = Net::HTTP::Post.new(uri)
          request["X-DV-Auth-Token"] = @token
          request["Content-Type"] = "application/json"
          request.body = JSON.generate(payload)

          response = Net::HTTP.start(
            uri.host,
            uri.port,
            use_ssl: uri.scheme == "https"
          ) do |http|
            http.request(request)
          end

          Rails.logger.info("BORZO STATUS: #{response.code}")
          Rails.logger.info("BORZO RESPONSE: #{response.body}")

          body = JSON.parse(response.body)

          unless response.is_a?(Net::HTTPSuccess) && body["is_successful"]
            raise StandardError, body["errors"]&.join(", ") || "Borzo API request failed"
          end

          body
        end
      end
    end
  end
end
