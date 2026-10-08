module Api
  module V1
    module Admin
      class CateringReservationsController < BaseController
        requires_permission "catering.read"

        def index
          render json: CateringReservation.order(created_at: :desc).map(&:as_public_json)
        end

        def show
          render json: CateringReservation.find(params[:id]).as_public_json
        end
      end
    end
  end
end
