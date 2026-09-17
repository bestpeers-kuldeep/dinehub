class TableReservationMailer < ApplicationMailer
  def reservation_confirmation(reservation)
    @reservation = reservation
    mail to: reservation.email, subject: "Reservation Confirmation"
  end
end
