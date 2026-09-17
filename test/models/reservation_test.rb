require "test_helper"

class ReservationTest < ActiveSupport::TestCase
  setup do
    @table = tables(:table_one)
    @date = Date.new(2026, 9, 16)
    @guest = {
      first_name: "Alex",
      last_name: "Guest",
      email: "alex@example.com",
      phone: "555-0100"
    }
  end

  test "11:30 slot leaves 12:00, 12:30, and 1pm free" do
    Reservation.create!(
      table: @table,
      reservation_date: @date,
      start_time: "11:30",
      **@guest
    )

    assert_equal "12:00", Reservation.last.estimated_end_time.strftime("%H:%M")
    assert_not @table.available_between?(@date, "11:30")
    assert @table.available_between?(@date, "12:00")
    assert @table.available_between?(@date, "12:30")
    assert @table.available_between?(@date, "13:00")
  end

  test "rejects a second booking in the same 30-minute slot" do
    Reservation.create!(
      table: @table,
      reservation_date: @date,
      start_time: "11:30",
      **@guest
    )

    overlap = Reservation.new(
      table: @table,
      reservation_date: @date,
      start_time: "11:30",
      first_name: "Sam",
      last_name: "Guest",
      email: "sam@example.com",
      phone: "555-0101"
    )

    assert_not overlap.valid?
    assert_includes overlap.errors[:base], "table is already booked around this arrival time"
  end

  test "allows a later slot on the same table" do
    Reservation.create!(
      table: @table,
      reservation_date: @date,
      start_time: "11:30",
      **@guest
    )

    later = Reservation.new(
      table: @table,
      reservation_date: @date,
      start_time: "12:30",
      first_name: "Sam",
      last_name: "Guest",
      email: "sam@example.com",
      phone: "555-0101"
    )

    assert later.valid?
  end

  test "rejects start times that are not 30-minute slots" do
    reservation = Reservation.new(
      table: @table,
      reservation_date: @date,
      start_time: "11:15",
      **@guest
    )

    assert_not reservation.valid?
    assert_includes reservation.errors[:start_time], "must be on a 30-minute slot"
  end
end
