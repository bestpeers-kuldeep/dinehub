require "test_helper"

class InquiryReservationMailerTest < ActionMailer::TestCase
  setup do
    @attrs = {
      full_name: "Alex Guest",
      phone: "555-0100",
      email: "alex@example.com",
      company: "Acme",
      reservation_date: Date.new(2026, 9, 16),
      start_time: "18:00",
      duration: "2 hours",
      budget_per_person: 45.00,
      number_of_people: 20,
      occasion: "Birthday",
      description: "Birthday dinner for 20",
      special_requests: "Wheelchair access near the bar",
      source: "website"
    }
  end

  test "party inquiry received" do
    reservation = PartiesReservation.new(@attrs.merge(id: 2101))
    email = InquiryReservationMailer.inquiry_received(reservation)

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal [ "alex@example.com" ], email.to
    assert_equal "We received your party inquiry", email.subject
    assert_includes email.html_part.body.to_s, "We've recorded your party inquiry"
    assert_includes email.text_part.body.to_s, "Our team will contact you soon"
    assert_includes email.text_part.body.to_s, "Birthday"
    assert_includes email.text_part.body.to_s, "Wheelchair access near the bar"
  end

  test "catering inquiry received" do
    reservation = CateringReservation.new(@attrs.merge(id: 3101, company: "Northwind"))
    email = InquiryReservationMailer.inquiry_received(reservation)

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal [ "alex@example.com" ], email.to
    assert_equal "We received your catering inquiry", email.subject
    assert_includes email.html_part.body.to_s, "We've recorded your catering inquiry"
    assert_includes email.text_part.body.to_s, "Northwind"
    assert_includes email.text_part.body.to_s, "Our team will contact you soon"
  end
end
