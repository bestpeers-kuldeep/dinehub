# Preview all emails at http://localhost:3000/rails/mailers/inquiry_reservation_mailer
class InquiryReservationMailerPreview < ActionMailer::Preview
  # http://localhost:3000/rails/mailers/inquiry_reservation_mailer/party_inquiry
  def party_inquiry
    InquiryReservationMailer.inquiry_received(sample_parties_reservation)
  end

  # http://localhost:3000/rails/mailers/inquiry_reservation_mailer/catering_inquiry
  def catering_inquiry
    InquiryReservationMailer.inquiry_received(sample_catering_reservation)
  end

  # http://localhost:3000/rails/mailers/inquiry_reservation_mailer/party_inquiry_from_database
  def party_inquiry_from_database
    reservation = PartiesReservation.last
    return party_inquiry if reservation.nil?

    InquiryReservationMailer.inquiry_received(reservation)
  end

  # http://localhost:3000/rails/mailers/inquiry_reservation_mailer/catering_inquiry_from_database
  def catering_inquiry_from_database
    reservation = CateringReservation.last
    return catering_inquiry if reservation.nil?

    InquiryReservationMailer.inquiry_received(reservation)
  end

  private

  def sample_parties_reservation
    PartiesReservation.new(
      id: 2101,
      full_name: "Alex Guest",
      email: "alex@example.com",
      phone: "555-0100",
      company: "Acme",
      reservation_date: Date.current + 10.days,
      start_time: "18:00",
      duration: "3 hours",
      budget_per_person: 55.00,
      number_of_people: 24,
      occasion: "Birthday",
      description: "Birthday dinner for 24 with a private toast at 8pm.",
      special_requests: "Wheelchair access near the bar",
      source: "website"
    )
  end

  def sample_catering_reservation
    CateringReservation.new(
      id: 3101,
      full_name: "Sam Taylor",
      email: "sam@example.com",
      phone: "555-0199",
      company: "Northwind",
      reservation_date: Date.current + 21.days,
      start_time: "12:00",
      duration: "4 hours",
      budget_per_person: 42.50,
      number_of_people: 80,
      occasion: "Corporate lunch",
      description: "Buffet lunch for an offsite, vegetarian options required.",
      special_requests: "Vegetarian options required",
      source: "website"
    )
  end
end
