module Api
  module V1
    module Admin
      class DashboardController < BaseController
        requires_permission "dashboard.read"

        def show
          from, to = date_range
          render json: ::Admin::DashboardSummary.new(from: from, to: to).call
        rescue ArgumentError => e
          render json: { errors: [ e.message ] }, status: :unprocessable_entity
        end

        private

        def date_range
          permitted = params.permit(:from, :to)
          from = parse_date(permitted[:from], :from) || Date.current
          to = parse_date(permitted[:to], :to) || Date.current
          raise ArgumentError, "from must be on or before to" if from > to

          [ from, to ]
        end

        def parse_date(value, name)
          return if value.blank?

          Date.iso8601(value.to_s)
        rescue Date::Error
          raise ArgumentError, "#{name} must be a date (YYYY-MM-DD)"
        end
      end
    end
  end
end
