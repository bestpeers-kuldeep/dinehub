module Api
  module V1
    module Admin
      class TablesController < BaseController
        requires_permission "tables.manage"

        before_action :set_table, only: %i[show update mark_available]

        def index
          tables = Table.order(:name)
          tables = tables.where(table_id: params[:table_id]) if params[:table_id].present?
          tables = tables.where(location: params[:location]) if params[:location].present?
          date, start_time = availability_window
          booked_ids = TableReservation.overlapping(date, start_time).distinct.pluck(:table_id).to_set

          render_collection(tables) do |records|
            counts = TableReservation.active.where(table_id: records.map(&:id)).group(:table_id).count
            records.map do |table|
              table_json(
                table,
                available: booked_ids.exclude?(table.id),
                active_reservations_count: counts[table.id] || 0
              )
            end
          end
        rescue ArgumentError => e
          render json: { errors: [ e.message ] }, status: :unprocessable_entity
        end

        def show
          render json: table_payload(@table).merge(
            reservations: @table.reservations.order(reservation_date: :desc, start_time: :desc).map(&:as_admin_json)
          )
        end

        def create
          table = Table.create!(table_params)
          render json: table_payload(table), status: :created
        rescue ActiveRecord::RecordInvalid => e
          render_validation_error(e)
        rescue ArgumentError => e
          render json: { errors: [ e.message ] }, status: :unprocessable_entity
        end

        def update
          @table.update!(table_params)
          render json: table_payload(@table)
        rescue ActiveRecord::RecordInvalid => e
          render_validation_error(e)
        rescue ArgumentError => e
          render json: { errors: [ e.message ] }, status: :unprocessable_entity
        end

        # Releases reservations so the table can be booked again.
        # With date and start_time, only the overlapping sitting is released.
        def mark_available
          released = reservations_to_release
          released_count = released.update_all(active: false, updated_at: Time.current)
          render json: table_payload(@table).merge(released_count: released_count)
        rescue ArgumentError => e
          render json: { errors: [ e.message ] }, status: :unprocessable_entity
        end

        private

        def set_table
          @table = Table.find(params[:id])
        end

        def table_params
          resource_params(:name, :location, :capacity)
        end

        def availability_window
          date = params[:date].presence || Date.current
          start_time = params[:start_time].presence || params[:time].presence || Time.current
          [ date, start_time ]
        end

        def reservations_to_release
          if params[:date].present? && (params[:start_time].present? || params[:time].present?)
            @table.reservations.overlapping(params[:date], params[:start_time].presence || params[:time])
          else
            @table.reservations.active
          end
        end

        def table_payload(table)
          date, start_time = availability_window
          table_json(
            table,
            available: table.available_between?(date, start_time),
            active_reservations_count: table.reservations.active.count
          )
        end

        def table_json(table, available:, active_reservations_count:)
          {
            id: table.id,
            name: table.name,
            location: table.location,
            capacity: table.capacity,
            available: available,
            active_reservations_count: active_reservations_count
          }
        end
      end
    end
  end
end
