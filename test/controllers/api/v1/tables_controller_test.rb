require "test_helper"

class Api::V1::TablesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @date = "2026-09-16"
  end

  test "requires date and start_time" do
    get "/api/v1/tables"
    assert_response :bad_request
  end

  test "returns available table counts by location without table names" do
    Reservation.create!(
      table: tables(:table_one),
      reservation_date: @date,
      start_time: "18:00",
      first_name: "Alex",
      last_name: "Guest",
      email: "alex@example.com",
      phone: "555-0100"
    )

    get "/api/v1/tables", params: { date: @date, start_time: "18:00" }

    assert_response :success
    body = JSON.parse(response.body)
    locations = body.fetch("locations")

    cocktail_bar = locations.find { |row| row["location"] == "Cocktail Bar" }
    patio = locations.find { |row| row["location"] == "Covered Patio" }

    assert_equal 1, cocktail_bar["available_tables"]
    assert_equal 1, patio["available_tables"]
    assert_nil body["tables"]
    refute_includes response.body, tables(:table_one).name
  end
end
