require "test_helper"

class InquiryReservations::CreateTest < ActiveSupport::TestCase
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
      source: "website",
      marketing_opt_in: true
    }
  end

  test "creates a parties reservation" do
    reservation = InquiryReservations::Create.call(
      reservation_class: PartiesReservation,
      attributes: @attrs
    )

    assert_instance_of PartiesReservation, reservation
    assert_equal "Alex Guest", reservation.full_name
    assert reservation.marketing_opt_in
    assert_nil reservation.table_id
  end

  test "creates a catering reservation" do
    reservation = InquiryReservations::Create.call(
      reservation_class: CateringReservation,
      attributes: @attrs.merge(company: "Northwind")
    )

    assert_instance_of CateringReservation, reservation
    assert_equal "Northwind", reservation.company
  end

  test "combines first and last name when full_name is omitted" do
    reservation = InquiryReservations::Create.call(
      reservation_class: PartiesReservation,
      attributes: @attrs.except(:full_name).merge(first_name: "Sam", last_name: "Taylor")
    )

    assert_equal "Sam Taylor", reservation.full_name
  end

  test "raises when required fields are missing" do
    assert_raises ActiveRecord::RecordInvalid do
      InquiryReservations::Create.call(
        reservation_class: PartiesReservation,
        attributes: { email: "alex@example.com", phone: "555-0100" }
      )
    end
  end
end
