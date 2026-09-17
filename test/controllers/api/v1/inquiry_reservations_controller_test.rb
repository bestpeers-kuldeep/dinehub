require "test_helper"

class Api::V1::InquiryReservationsControllerTest < ActionDispatch::IntegrationTest
  include ActionMailer::TestHelper

  setup do
    @params = {
      full_name: "Alex Guest",
      phone: "555-0100",
      email: "alex@example.com",
      company: "Acme",
      reservation_date: "2026-09-16",
      start_time: "18:00",
      duration: "2 hours",
      budget_per_person: 45.00,
      number_of_people: 20,
      occasion: "Birthday",
      description: "Birthday dinner for 20",
      source: "website"
    }
  end

  test "creates a parties reservation" do
    assert_enqueued_emails 1 do
      assert_difference -> { PartiesReservation.count }, 1 do
        post "/api/v1/parties_reservations", params: @params
      end
    end

    assert_response :created
    body = JSON.parse(response.body)
    assert_equal "PartiesReservation", body["type"]
    assert_equal "Alex Guest", body["full_name"]
    assert_equal "2 hours", body["duration"]
    assert_equal "Birthday", body["occasion"]
    assert_equal 20, body["number_of_people"]
    assert_equal false, body["marketing_opt_in"]
    refute body.key?("table_id")
  end

  test "creates a parties reservation from first and last name" do
    params = @params.except(:full_name).merge(first_name: "Sam", last_name: "Taylor", marketing_opt_in: true)

    post "/api/v1/parties_reservations", params: params

    assert_response :created
    body = JSON.parse(response.body)
    assert_equal "Sam Taylor", body["full_name"]
    assert_equal true, body["marketing_opt_in"]
  end

  test "creates a catering reservation" do
    assert_enqueued_emails 1 do
      assert_difference -> { CateringReservation.count }, 1 do
        post "/api/v1/catering_reservations", params: @params.merge(company: "Northwind")
      end
    end

    assert_response :created
    body = JSON.parse(response.body)
    assert_equal "CateringReservation", body["type"]
    assert_equal "Northwind", body["company"]
  end

  test "does not reduce dining table availability" do
    post "/api/v1/parties_reservations", params: @params
    assert_response :created

    get "/api/v1/tables", params: { date: @params[:reservation_date], start_time: "18:00", location: "Cocktail Bar" }
    body = JSON.parse(response.body)
    assert_equal 2, body["locations"].first["available_tables"]
  end

  test "rejects a parties reservation without required fields" do
    post "/api/v1/parties_reservations", params: { email: "alex@example.com" }
    assert_response :unprocessable_entity
  end
end
