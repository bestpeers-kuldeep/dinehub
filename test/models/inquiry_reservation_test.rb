require "test_helper"

class InquiryReservationTest < ActiveSupport::TestCase
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
      source: "website"
    }
  end

  test "creates a parties reservation without a dining table" do
    reservation = PartiesReservation.create!(@attrs)

    assert_equal "PartiesReservation", reservation.type
    assert_nil reservation.table_id
    assert_equal "Alex Guest", reservation.full_name
  end

  test "creates a catering reservation without a dining table" do
    reservation = CateringReservation.create!(@attrs.merge(company: "Northwind"))

    assert_equal "CateringReservation", reservation.type
    assert_nil reservation.table_id
  end

  test "requires inquiry fields" do
    reservation = PartiesReservation.new(email: "alex@example.com", phone: "555-0100")

    assert_not reservation.valid?
    assert_includes reservation.errors[:full_name], "can't be blank"
    assert_includes reservation.errors[:duration], "can't be blank"
    assert_includes reservation.errors[:budget_per_person], "can't be blank"
  end
end
