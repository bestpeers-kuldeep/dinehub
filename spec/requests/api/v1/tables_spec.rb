require "swagger_helper"

RSpec.describe "Tables API", type: :request do
  path "/api/v1/tables" do
    get "List table availability by location" do
      tags "Tables"
      produces "application/json"
      parameter name: :date, in: :query, type: :string, format: :date, required: true
      parameter name: :start_time, in: :query, type: :string, required: true
      parameter name: :location, in: :query, schema: { "$ref" => "#/components/schemas/Location" }, required: false
      parameter name: :capacity, in: :query, type: :integer, required: false

      response "200", "availability returned" do
        let(:date) { attributes_for(:table_reservation)[:reservation_date].to_s }
        let(:start_time) { "18:00" }
        let(:location) { nil }
        let(:capacity) { nil }
        let!(:booked_table) { create(:table, location: "Cocktail Bar") }
        let!(:available_table) { create(:table, location: "Cocktail Bar") }
        let!(:patio_table) { create(:table, location: "Covered Patio") }
        let!(:reservation) do
          create(
            :table_reservation,
            table: booked_table,
            reservation_date: date,
            start_time: start_time
          )
        end

        run_test! do |response|
          payload = JSON.parse(response.body)
          cocktail_bar = payload.fetch("locations").find { |row| row["location"] == "Cocktail Bar" }
          patio = payload.fetch("locations").find { |row| row["location"] == "Covered Patio" }

          expect(cocktail_bar["available_tables"]).to eq(1)
          expect(patio["available_tables"]).to eq(1)
          expect(payload["tables"]).to be_nil
          expect(response.body).not_to include(booked_table.name)
        end
      end

      response "400", "date or start time is missing" do
        let(:date) { nil }
        let(:start_time) { nil }
        let(:location) { nil }
        let(:capacity) { nil }
        run_test!
      end
    end
  end
end
