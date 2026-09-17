require "test_helper"

class TableReservationMailerTest < ActionMailer::TestCase
  test "reservation confirmation" do
    reservation = reservations(:lunch_slot)
    email = TableReservationMailer.reservation_confirmation(reservation)

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal [ reservation.email ], email.to
    assert_equal "Reservation Confirmation", email.subject
    assert_includes email.html_part.body.to_s, reservation.full_name
    assert_includes email.text_part.body.to_s, "Cocktail Bar"
    assert_includes email.text_part.body.to_s, "11:30"
  end
end
