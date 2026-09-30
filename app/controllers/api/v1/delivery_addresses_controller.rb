module Api
  module V1
    class DeliveryAddressesController < BaseController
      before_action :authenticate_user!
      before_action :set_delivery_address, only: %i[show update destroy]

      def index
        render json: current_user.delivery_addresses.ordered
      end

      def show
        render json: @delivery_address
      end

      # Keeping a single default per user is handled by the model callback and
      # enforced by a partial unique index, so the controller only persists.
      def create
        delivery_address = current_user.delivery_addresses.create!(delivery_address_params)

        render json: delivery_address, status: :created
      rescue ActiveRecord::RecordInvalid => e
        render_errors(e.record)
      end

      def update
        @delivery_address.update!(delivery_address_params)

        render json: @delivery_address
      rescue ActiveRecord::RecordInvalid => e
        render_errors(e.record)
      end

      def destroy
        @delivery_address.destroy!

        render json: { message: "Delivery address deleted successfully" }
      rescue ActiveRecord::RecordNotDestroyed => e
        render_errors(e.record)
      end

      private

      def set_delivery_address
        @delivery_address = current_user.delivery_addresses.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Delivery address not found" }, status: :not_found
      end

      def delivery_address_params
        params.require(:delivery_address).permit(
          :address_line,
          :city,
          :state,
          :postal_code,
          :landmark,
          :latitude,
          :longitude,
          :is_default
        )
      end

      def render_errors(record)
        render json: { errors: record.errors.full_messages }, status: :unprocessable_entity
      end
    end
  end
end
