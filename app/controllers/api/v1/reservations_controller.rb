module Api
  module V1
    class ReservationsController < BaseController
      def create
        unless location.present? && reservation_params[:reservation_date].present? && reservation_params[:start_time].present?
          render json: { errors: [ "location, reservation_date, and start_time are required" ] }, status: :bad_request
          return
        end

        reservation = nil
        TableReservation.transaction do
          table = Table.lock_available_for(
            location: location,
            date: reservation_params[:reservation_date],
            start_time: reservation_params[:start_time],
            capacity: party_size
          )

          if table.nil?
            render json: { errors: [ "no tables available at this location for the requested time" ] }, status: :unprocessable_entity
            raise ActiveRecord::Rollback
          end

          reservation = table.reservations.create!(guest_params)
        end

        return if performed?

        render json: reservation.as_public_json, status: :created
      rescue ActiveRecord::RecordInvalid => e
        render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
      rescue ActiveRecord::RecordNotUnique
        render json: { errors: [ "no tables available at this location for the requested time" ] }, status: :conflict
      rescue StandardError => e
        render json: { error: e.message }, status: :internal_server_error
      end

      private

      def location
        params[:location].presence || params.dig(:reservation, :location)
      end

      def party_size
        params[:capacity].presence || params.dig(:reservation, :capacity)
      end

      def reservation_params
        permitted = %i[
          location reservation_date start_time capacity
          first_name last_name email phone occasion special_requests marketing_opt_in
        ]
        if params[:reservation].present?
          params.require(:reservation).permit(permitted)
        else
          params.permit(permitted)
        end
      end

      def guest_params
        reservation_params.except(:location, :capacity, :first_name, :last_name).merge(
          full_name: Reservations::FullName.from(reservation_params)
        )
      end
    end
  end
end
