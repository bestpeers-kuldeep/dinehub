module Api
  module V1
    class PartiesReservationsController < InquiryReservationsController
      private

      def reservation_class
        PartiesReservation
      end

      def param_key
        :parties_reservation
      end
    end
  end
end
