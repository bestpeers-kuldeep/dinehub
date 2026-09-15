module Api
  module V1
    class EventsController < BaseController
      def index
        events = Event.all
        render json: events.as_json
      rescue StandardError => e
        render json: { error: e.message }, status: :internal_server_error
      end

      def show
        event = Event.includes(:event_items).find(params[:id])
        render json: event.as_json(include: :event_items)
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Event not found" }, status: :not_found
      rescue StandardError => e
        render json: { error: e.message }, status: :internal_server_error
      end
    end
  end
end
