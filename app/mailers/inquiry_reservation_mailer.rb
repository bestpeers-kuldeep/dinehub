class InquiryReservationMailer < ApplicationMailer
  def inquiry_received(reservation)
    @reservation = reservation
    @kind = reservation.inquiry_kind
    @kind_label = @kind == "catering" ? "catering" : "party"

    mail to: reservation.email, subject: "We received your #{@kind_label} inquiry"
  end
end
