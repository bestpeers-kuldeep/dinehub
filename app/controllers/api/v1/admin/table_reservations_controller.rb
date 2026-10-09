module Api
  module V1
    module Admin
      class TableReservationsController < BaseController
        requires_permission "table_reservations.manage"

        before_action :set_reservation, only: %i[show destroy deactivate]

        def index
          reservations = TableReservation.includes(:table).order(reservation_date: :desc, start_time: :desc)
          reservations = reservations.where(table_id: params[:table_id]) if params[:table_id].present?
          reservations = reservations.where(reservation_date: params[:date]) if params[:date].present?
          if params[:active].present?
            reservations = reservations.where(active: ActiveModel::Type::Boolean.new.cast(params[:active]))
          end

          render_collection(reservations) { |records| records.map(&:as_admin_json) }
        end

        def show
          render json: @reservation.as_admin_json
        end

        def destroy
          @reservation.destroy!
          head :no_content
        end

        def deactivate
          @reservation.update!(active: false)
          render json: @reservation.as_admin_json
        rescue ActiveRecord::RecordInvalid => e
          render_validation_error(e)
        end

        def estimated_duration
          if request.patch?
            TableReservation.assign_estimated_duration!(params[:estimated_duration_minutes])
          end

          render json: duration_payload
        rescue ArgumentError => e
          render json: { errors: [ e.message ] }, status: :unprocessable_entity
        end

        private

        def set_reservation
          @reservation = TableReservation.find(params[:id])
        end

        def duration_payload
          {
            estimated_duration_minutes: TableReservation.estimated_duration.in_minutes.to_i,
            slot_minutes: TableReservation::SLOT_MINUTES
          }
        end
      end
    end
  end
end
