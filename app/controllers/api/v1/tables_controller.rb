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
          capacity: params[:capacity],
          duration_minutes: duration_minutes
        )
        tables = Table.availability_details(
          date: date,
          start_time: start_time,
          location: params[:location],
          capacity: params[:capacity],
          duration_minutes: duration_minutes
        )

        render json: {
          date: date,
          start_time: start_time,
          estimated_duration_minutes: duration_minutes,
          estimated_end_time: (
            Reservation.coerce_time(start_time) + duration_minutes.minutes
          ).strftime("%H:%M"),
          tables: tables,
          locations: locations
        }
      rescue ArgumentError, TypeError => e
        render json: { error: e.message }, status: :bad_request
      rescue StandardError => e
        render json: { error: e.message }, status: :internal_server_error
      end

      private

      def duration_minutes
        value = Integer(
          params[:estimated_duration_minutes].presence ||
          TableReservation::DEFAULT_ESTIMATED_DURATION_MINUTES
        )
        raise ArgumentError, "estimated_duration_minutes must be between 1 and 1440" unless value.between?(1, 1440)

        value
      end
    end
  end
end
