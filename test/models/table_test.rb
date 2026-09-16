require "test_helper"

class TableTest < ActiveSupport::TestCase
  test "is valid with capacity under 20" do
    table = Table.new(name: "Table 9", capacity: 8, location: "Covered Patio", status: :available)

    assert table.valid?
  end

  test "is invalid when capacity is 20 or more" do
    table = Table.new(name: "Table 10", capacity: 20, location: "Cocktail Bar", status: :available)

    assert_not table.valid?
    assert_includes table.errors[:capacity], "must be less than 20"
  end

  test "is invalid without a name" do
    table = Table.new(capacity: 4, location: "Cocktail Bar", status: :available)

    assert_not table.valid?
    assert_includes table.errors[:name], "can't be blank"
  end
end
