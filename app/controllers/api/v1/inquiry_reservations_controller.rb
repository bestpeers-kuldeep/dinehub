module Api
  module V1
    class InquiryReservationsController < BaseController
      def create
        reservation = InquiryReservations::Create.call(
          reservation_class: reservation_class,
          attributes: inquiry_params
        )
        render json: reservation.as_public_json, status: :created
      rescue ActiveRecord::RecordInvalid => e
        render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
      rescue StandardError => e
        render json: { error: e.message }, status: :internal_server_error
      end

      private

      def reservation_class
        raise NotImplementedError
      end

      def param_key
        raise NotImplementedError
      end

      def inquiry_params
        permitted = %i[
          full_name first_name last_name phone email company
          reservation_date start_time duration budget_per_person number_of_people
          occasion description special_requests source marketing_opt_in
        ]
        nested = params[param_key].presence || params[:reservation]
        if nested.present?
          params.require(nested_key).permit(permitted)
        else
          params.permit(permitted)
        end
      end

      def nested_key
        params[param_key].present? ? param_key : :reservation
      end
    end
  end
end
