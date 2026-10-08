module Api
  module V1
    module Admin
      class BaseController < Api::V1::BaseController
        include Authorizable

        before_action :authenticate_user!
        before_action :authorize_permission!

        private

        def resource_params(*keys, key: controller_name.singularize)
          source = params[key].present? ? params.require(key) : params
          source.permit(*keys)
        end

        def render_validation_error(exception)
          render json: { errors: exception.record.errors.full_messages }, status: :unprocessable_entity
        end

        def render_destroy_error(exception)
          messages = exception.record.errors.full_messages
          messages = [ exception.message ] if messages.empty?
          render json: { errors: messages }, status: :unprocessable_entity
        end
      end
    end
  end
end
