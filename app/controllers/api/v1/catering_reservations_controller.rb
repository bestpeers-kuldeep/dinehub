module Api
  module V1
    class CateringReservationsController < InquiryReservationsController
      private

      def reservation_class
        CateringReservation
      end

      def param_key
        :catering_reservation
      end
    end
  end
end
