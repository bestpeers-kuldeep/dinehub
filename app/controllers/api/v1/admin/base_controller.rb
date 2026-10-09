module Api
  module V1
    module Admin
      class BaseController < Api::V1::BaseController
        include Authorizable
        include Paginatable

        before_action :authenticate_user!
        before_action :authorize_permission!

        private

        def resource_params(*keys, key: controller_name.singularize)
          source = params[key].present? ? params.require(key) : params
          source.permit(*keys)
        end

        # Query or JSON: `page` (default 1) and `per_page` (default 25, max 100).
        def pagination_params
          permitted = params.permit(:page, :per_page)
          page = permitted[:page].to_i
          per_page = permitted[:per_page].to_i

          {
            page: page.positive? ? page : 1,
            per_page: per_page.positive? ? [ per_page, Paginatable::MAX_PER_PAGE ].min : Paginatable::DEFAULT_PER_PAGE
          }
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
