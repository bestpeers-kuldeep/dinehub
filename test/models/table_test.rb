require "test_helper"

class TableTest < ActiveSupport::TestCase
  test "is valid with capacity under 20" do
    table = Table.new(name: "Table 9", capacity: 8, location: "Covered Patio")

    assert table.valid?
  end

  test "is invalid when capacity is 20 or more" do
    table = Table.new(name: "Table 10", capacity: 20, location: "Cocktail Bar")

    assert_not table.valid?
    assert_includes table.errors[:capacity], "must be less than 20"
  end

  test "is invalid without a name" do
    table = Table.new(capacity: 4, location: "Cocktail Bar")

    assert_not table.valid?
    assert_includes table.errors[:name], "can't be blank"
  end

  test "availability by location omits tables already booked in that slot" do
    date = Date.new(2026, 9, 16)
    Reservation.create!(
      table: tables(:table_one),
      reservation_date: date,
      start_time: "11:30",
      first_name: "Alex",
      last_name: "Guest",
      email: "alex@example.com",
      phone: "555-0100"
    )

    booked_slot = Table.availability_by_location(date: date, start_time: "11:30")
    later_slot = Table.availability_by_location(date: date, start_time: "12:30")
    cocktail_booked = booked_slot.find { |row| row[:location] == "Cocktail Bar" }
    cocktail_later = later_slot.find { |row| row[:location] == "Cocktail Bar" }

    assert_equal 1, cocktail_booked[:available_tables]
    assert_equal 2, cocktail_later[:available_tables]
  end
end
