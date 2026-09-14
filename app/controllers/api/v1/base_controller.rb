module Api
  module V1
    class BaseController < ApplicationController
      before_action :authenticate_api_key!

      private

      def authenticate_api_key!
        provided_key = request.headers["X-Api-Key"].to_s
        binding.pry
        expected_key = ENV.fetch("API_KEY")

        unless api_key_valid?(provided_key, expected_key)
          render json: { error: "Unauthorized" }, status: :unauthorized
        end
      end

      def api_key_valid?(provided_key, expected_key)
        return false if provided_key.blank? || expected_key.blank?

        ActiveSupport::SecurityUtils.secure_compare(
          Digest::SHA256.hexdigest(provided_key),
          Digest::SHA256.hexdigest(expected_key)
        )
      end
    end
  end
end
