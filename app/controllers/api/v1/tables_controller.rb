module Api
  module V1
    class TablesController < BaseController
      def index
        date = params[:date]
        start_time = params[:start_time].presence || params[:time]

        if date.blank? || start_time.blank?
          render json: { error: "date and start_time are required" }, status: :bad_request
          return
        end

        locations = Table.availability_by_location(
          date: date,
          start_time: start_time,
          location: params[:location],
          capacity: params[:capacity]
        )

        render json: {
          date: date,
          start_time: start_time,
          locations: locations
        }
      rescue ArgumentError, TypeError => e
        render json: { error: e.message }, status: :bad_request
      rescue StandardError => e
        render json: { error: e.message }, status: :internal_server_error
      end
    end
  end
end
