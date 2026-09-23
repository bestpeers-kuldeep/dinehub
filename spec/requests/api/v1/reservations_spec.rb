require "swagger_helper"

RSpec.describe "Table reservations API", type: :request do
  let!(:small_table) { create(:table, capacity: 2, location: "Cocktail Bar") }
  let!(:large_table) { create(:table, capacity: 4, location: "Cocktail Bar") }
  let(:guest) { attributes_for(:table_reservation, :dinner) }
  let(:reservation_attributes) do
    {
      location: "Cocktail Bar",
      reservation_date: guest[:reservation_date].to_s,
      start_time: guest[:start_time],
      number_of_people: 2,
      first_name: "Alex",
      last_name: "Guest",
      email: guest[:email],
      phone: guest[:phone]
    }
  end

  path "/api/v1/reservations" do
    post "Create a dining table reservation" do
      tags "Reservations"
      consumes "application/json"
      produces "application/json"
      parameter name: :reservation, in: :body,
        schema: { "$ref" => "#/components/schemas/TableReservationRequest" }

      response "201", "reservation created" do
        let(:reservation) { reservation_attributes }

        run_test! do |response|
          payload = JSON.parse(response.body)

          expect(payload).to include(
            "location" => "Cocktail Bar",
            "type" => "TableReservation",
            "start_time" => reservation_attributes[:start_time],
            "estimated_end_time" => "20:00",
            "number_of_people" => 2,
            "full_name" => "Alex Guest"
          )
          expect(payload).not_to have_key("first_name")
          expect(payload).not_to have_key("last_name")
          expect(payload["table_id"]).to be_nil
          expect(response.body).not_to include(small_table.name)
        end
      end

      response "422", "validation failed or no table is available" do
        let(:reservation) { reservation_attributes.except(:first_name, :last_name) }

        run_test! do |response|
          errors = JSON.parse(response.body).fetch("errors")

          expect(errors).to include("First name can't be blank", "Last name can't be blank")
          expect(errors).not_to include("Full name can't be blank")
        end
      end
    end
  end

  it "persists the reservation and enqueues its confirmation" do
    expect {
      post "/api/v1/reservations", params: reservation_attributes
    }.to change(TableReservation, :count).by(1)
      .and have_enqueued_mail(TableReservationMailer, :reservation_confirmation)

    reservation = TableReservation.last
    expect(reservation.full_name).to eq("Alex Guest")
    expect(reservation.number_of_people).to eq(2)
  end

  it "accepts full_name without first and last names" do
    params = reservation_attributes.except(:first_name, :last_name).merge(full_name: guest[:full_name])

    post "/api/v1/reservations", params: params, as: :json

    expect(response).to have_http_status(:created)
    expect(json_body["full_name"]).to eq(guest[:full_name])
  end

  it "reduces location availability after a booking" do
    post "/api/v1/reservations", params: reservation_attributes

    get "/api/v1/tables", params: {
      date: reservation_attributes[:reservation_date],
      start_time: reservation_attributes[:start_time],
      location: "Cocktail Bar"
    }

    expect(json_body.fetch("locations").first["available_tables"]).to eq(1)
  end

  it "rejects a booking when the location is full for the window" do
    2.times do |index|
      applicant = attributes_for(:user)
      post "/api/v1/reservations", params: reservation_attributes.merge(
        first_name: applicant[:first_name],
        last_name: applicant[:last_name],
        email: "guest#{index}@example.com"
      )
      expect(response).to have_http_status(:created)
    end

    post "/api/v1/reservations", params: reservation_attributes.merge(email: "late@example.com")

    expect(response).to have_http_status(:unprocessable_entity)
  end

  it "assigns a table that can seat the party" do
    post "/api/v1/reservations", params: reservation_attributes.merge(number_of_people: 4)

    expect(response).to have_http_status(:created)
    expect(json_body["number_of_people"]).to eq(4)
    expect(TableReservation.last.table_id).to eq(large_table.id)
  end
end
