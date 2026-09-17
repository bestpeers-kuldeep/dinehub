require "test_helper"

class ReservationTest < ActiveSupport::TestCase
  setup do
    @table = tables(:table_one)
    @date = Date.new(2026, 9, 16)
    @guest = {
      full_name: "Alex Guest",
      email: "alex@example.com",
      phone: "555-0100"
    }
  end

  test "11:30 slot holds the table for two hours" do
    TableReservation.create!(
      table: @table,
      reservation_date: @date,
      start_time: "11:30",
      **@guest
    )

    assert_equal "13:30", TableReservation.last.estimated_end_time.strftime("%H:%M")
    assert_not @table.available_between?(@date, "11:30")
    assert_not @table.available_between?(@date, "12:00")
    assert_not @table.available_between?(@date, "12:30")
    assert_not @table.available_between?(@date, "13:00")
    assert @table.available_between?(@date, "13:30")
  end

  test "rejects a second booking in the same 30-minute slot" do
    TableReservation.create!(
      table: @table,
      reservation_date: @date,
      start_time: "11:30",
      **@guest
    )

    overlap = TableReservation.new(
      table: @table,
      reservation_date: @date,
      start_time: "11:30",
      full_name: "Sam Guest",
      email: "sam@example.com",
      phone: "555-0101"
    )

    assert_not overlap.valid?
    assert_includes overlap.errors[:base], "table is already booked around this arrival time"
  end

  test "allows a slot after the two-hour window on the same table" do
    TableReservation.create!(
      table: @table,
      reservation_date: @date,
      start_time: "11:30",
      **@guest
    )

    later = TableReservation.new(
      table: @table,
      reservation_date: @date,
      start_time: "13:30",
      full_name: "Sam Guest",
      email: "sam@example.com",
      phone: "555-0101"
    )

    assert later.valid?
  end

  test "rejects start times that are not 30-minute slots" do
    reservation = TableReservation.new(
      table: @table,
      reservation_date: @date,
      start_time: "11:15",
      **@guest
    )

    assert_not reservation.valid?
    assert_includes reservation.errors[:start_time], "must be on a 30-minute slot"
  end
end
