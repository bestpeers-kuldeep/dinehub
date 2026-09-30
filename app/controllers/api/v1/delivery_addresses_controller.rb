module Api
  module V1
    class DeliveryAddressesController < BaseController
      before_action :authenticate_user!
      before_action :set_delivery_address, only: %i[show update destroy]

      def index
        delivery_addresses = current_user.delivery_addresses
                                         .order(is_default: :desc, created_at: :desc)

        render json: delivery_addresses
      end

      def show
        render json: @delivery_address
      end

      def create
        delivery_address = current_user.delivery_addresses.new(delivery_address_params)

        DeliveryAddress.transaction do
          if delivery_address.is_default?
            current_user.delivery_addresses
                        .where(is_default: true)
                        .update_all(is_default: false)
          end

          delivery_address.save!
        end

        render json: delivery_address, status: :created
      rescue ActiveRecord::RecordInvalid => e
        render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
      end

      def update
        DeliveryAddress.transaction do
          if delivery_address_params[:is_default] == true
            current_user.delivery_addresses
                        .where.not(id: @delivery_address.id)
                        .where(is_default: true)
                        .update_all(is_default: false)
          end

          @delivery_address.update!(delivery_address_params)
        end

        render json: @delivery_address
      rescue ActiveRecord::RecordInvalid => e
        render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
      end

      def destroy
        @delivery_address.destroy!

        render json: { message: "Delivery address deleted successfully" }
      rescue StandardError => e
        render json: { error: e.message }, status: :unprocessable_entity
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
    end
  end
end
