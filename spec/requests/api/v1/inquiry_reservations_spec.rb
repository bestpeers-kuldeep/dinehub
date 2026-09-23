require "swagger_helper"

RSpec.describe "Inquiry reservations API", type: :request do
  let(:inquiry_attributes) do
    attributes_for(:parties_reservation).merge(
      special_requests: "Wheelchair access near the bar"
    )
  end

  path "/api/v1/parties_reservations" do
    post "Create a parties inquiry" do
      tags "Reservations"
      consumes "application/json"
      produces "application/json"
      parameter name: :inquiry, in: :body,
        schema: { "$ref" => "#/components/schemas/InquiryReservationRequest" }

      response "201", "inquiry created" do
        let(:inquiry) { inquiry_attributes }

        run_test! do |response|
          payload = JSON.parse(response.body)

          expect(payload).to include(
            "type" => "PartiesReservation",
            "full_name" => inquiry_attributes[:full_name],
            "duration" => inquiry_attributes[:duration],
            "occasion" => inquiry_attributes[:occasion],
            "number_of_people" => inquiry_attributes[:number_of_people],
            "special_requests" => inquiry_attributes[:special_requests],
            "marketing_opt_in" => false
          )
          expect(payload).not_to have_key("table_id")
        end
      end

      response "422", "validation failed" do
        let(:inquiry) { { email: inquiry_attributes[:email] } }
        run_test!
      end
    end
  end

  path "/api/v1/catering_reservations" do
    post "Create a catering inquiry" do
      tags "Reservations"
      consumes "application/json"
      produces "application/json"
      parameter name: :inquiry, in: :body,
        schema: { "$ref" => "#/components/schemas/InquiryReservationRequest" }

      response "201", "inquiry created" do
        let(:inquiry) { attributes_for(:catering_reservation).merge(special_requests: inquiry_attributes[:special_requests]) }

        run_test! do |response|
          payload = JSON.parse(response.body)

          expect(payload["type"]).to eq("CateringReservation")
          expect(payload["company"]).to eq(inquiry[:company])
          expect(payload["special_requests"]).to eq(inquiry[:special_requests])
        end
      end

      response "422", "validation failed" do
        let(:inquiry) { { email: inquiry_attributes[:email] } }
        run_test!
      end
    end
  end

  it "combines first and last name and accepts JSON" do
    person = attributes_for(:user)
    params = inquiry_attributes.except(:full_name).merge(
      first_name: person[:first_name],
      last_name: person[:last_name],
      marketing_opt_in: true
    )

    post "/api/v1/parties_reservations", params: params, as: :json

    expect(response).to have_http_status(:created)
    expect(json_body).to include(
      "full_name" => "#{person[:first_name]} #{person[:last_name]}",
      "marketing_opt_in" => true
    )
  end

  it "does not reduce dining-table availability" do
    create_list(:table, 2, location: "Cocktail Bar")

    post "/api/v1/parties_reservations", params: inquiry_attributes
    get "/api/v1/tables", params: {
      date: inquiry_attributes[:reservation_date],
      start_time: inquiry_attributes[:start_time],
      location: "Cocktail Bar"
    }

    expect(json_body.fetch("locations").first["available_tables"]).to eq(2)
  end

  it "persists the inquiry and enqueues its receipt email" do
    expect {
      post "/api/v1/parties_reservations", params: inquiry_attributes
    }.to change(PartiesReservation, :count).by(1)
      .and have_enqueued_mail(InquiryReservationMailer, :inquiry_received)
  end
end
