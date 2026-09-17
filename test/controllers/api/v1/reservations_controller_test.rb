require "test_helper"

class Api::V1::ReservationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @params = {
      location: "Cocktail Bar",
      reservation_date: "2026-09-16",
      start_time: "18:00",
      first_name: "Alex",
      last_name: "Guest",
      email: "alex@example.com",
      phone: "555-0100"
    }
  end

  test "creates a reservation against a hidden table in the location" do
    assert_difference -> { Reservation.count }, 1 do
      post "/api/v1/reservations", params: @params
    end

    assert_response :created
    body = JSON.parse(response.body)
    assert_equal "Cocktail Bar", body["location"]
    assert_equal "TableReservation", body["type"]
    assert_equal "18:00", body["start_time"]
    assert_equal "20:00", body["estimated_end_time"]
    assert_equal "Alex Guest", body["full_name"]
    refute body.key?("first_name")
    refute body.key?("last_name")
    assert_nil body["table_id"]
    refute_includes response.body, tables(:table_one).name
    assert_equal "Alex Guest", TableReservation.last.full_name
  end

  test "reduces location availability after a booking" do
    post "/api/v1/reservations", params: @params
    assert_response :created

    get "/api/v1/tables", params: { date: @params[:reservation_date], start_time: "18:00", location: "Cocktail Bar" }
    body = JSON.parse(response.body)
    assert_equal 1, body["locations"].first["available_tables"]
  end

  test "rejects a booking when the location is full for the window" do
    2.times do |index|
      post "/api/v1/reservations", params: @params.merge(
        first_name: "Guest#{index}",
        last_name: "Party",
        email: "guest#{index}@example.com"
      )
      assert_response :created
    end

    post "/api/v1/reservations", params: @params.merge(first_name: "Late", last_name: "Guest", email: "late@example.com")
    assert_response :unprocessable_entity
  end
end
