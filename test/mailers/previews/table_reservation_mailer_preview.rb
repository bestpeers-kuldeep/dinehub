# Preview all emails at http://localhost:3000/rails/mailers/table_reservation_mailer
class TableReservationMailerPreview < ActionMailer::Preview
  # http://localhost:3000/rails/mailers/table_reservation_mailer/reservation_confirmation
  def reservation_confirmation
    TableReservationMailer.reservation_confirmation(sample_reservation)
  end

  # http://localhost:3000/rails/mailers/table_reservation_mailer/reservation_confirmation_with_occasion
  def reservation_confirmation_with_occasion
    TableReservationMailer.reservation_confirmation(
      sample_reservation(
        occasion: "Anniversary",
        special_requests: "Window table if possible, and a candle on the dessert."
      )
    )
  end

  # http://localhost:3000/rails/mailers/table_reservation_mailer/reservation_confirmation_from_database
  def reservation_confirmation_from_database
    reservation = TableReservation.last
    return reservation_confirmation if reservation.nil?

    TableReservationMailer.reservation_confirmation(reservation)
  end

  private

  # Built in memory so previews work on an empty database.
  def sample_reservation(attributes = {})
    TableReservation.new({
      id: 1042,
      table: Table.first || Table.new(name: "Table 12", capacity: 2, location: "Dining Room"),
      reservation_date: Date.current + 3.days,
      start_time: "19:00",
      full_name: "Alex Guest",
      email: "alex@example.com",
      phone: "555-0100"
    }.merge(attributes))
  end
end
