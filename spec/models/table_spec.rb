require "rails_helper"

RSpec.describe Table, type: :model do
  it "is valid with capacity under 20" do
    table = build(:table, name: "Table 9", capacity: 8, location: "Covered Patio")

    expect(table).to be_valid
  end

  it "is invalid when capacity is 20 or more" do
    table = build(:table, name: "Table 10", capacity: 20, location: "Cocktail Bar")

    expect(table).not_to be_valid
    expect(table.errors[:capacity]).to include("must be less than 20")
  end

  it "is invalid without a name" do
    table = build(:table, name: nil, capacity: 4, location: "Cocktail Bar")

    expect(table).not_to be_valid
    expect(table.errors[:name]).to include("can't be blank")
  end

  it "omits tables already booked in that slot from availability by location" do
    date = Date.new(2026, 9, 16)
    booked_table = create(:table, location: "Cocktail Bar")
    create(:table, location: "Cocktail Bar")
    create(:table, :covered_patio)
    create(
      :table_reservation,
      table: booked_table,
      reservation_date: date,
      start_time: "11:30"
    )

    booked_slot = described_class.availability_by_location(date: date, start_time: "11:30")
    overlapping_slot = described_class.availability_by_location(date: date, start_time: "12:30")
    later_slot = described_class.availability_by_location(date: date, start_time: "13:30")
    cocktail_booked = booked_slot.find { |row| row[:location] == "Cocktail Bar" }
    cocktail_overlapping = overlapping_slot.find { |row| row[:location] == "Cocktail Bar" }
    cocktail_later = later_slot.find { |row| row[:location] == "Cocktail Bar" }

    expect(cocktail_booked[:available_tables]).to eq(1)
    expect(cocktail_overlapping[:available_tables]).to eq(1)
    expect(cocktail_later[:available_tables]).to eq(2)
  end
end
