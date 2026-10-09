require "rails_helper"

RSpec.describe "Admin table reservations API", type: :request do
  let(:headers) { auth_headers_for(create(:user, :admin)) }
  let(:table) { create(:table) }
  let(:date) { Date.new(2026, 9, 16) }

  it "lists, shows, and deletes a reservation" do
    reservation = create(:table_reservation, table: table, reservation_date: date, start_time: "11:30")
    create(:table_reservation, reservation_date: date, start_time: "18:00")

    get "/api/v1/admin/table_reservations",
      params: { table_id: table.id, per_page: 10 },
      headers: headers

    expect(response).to have_http_status(:ok)
    expect(json_body.fetch("data").map { |row| row["id"] }).to eq([ reservation.id ])
    expect(json_body["data"].first).to include(
      "table_id" => table.id,
      "table_name" => table.name,
      "active" => true,
      "estimated_duration_minutes" => 120
    )

    get "/api/v1/admin/table_reservations/#{reservation.id}", headers: headers

    expect(response).to have_http_status(:ok)
    expect(json_body["id"]).to eq(reservation.id)

    delete "/api/v1/admin/table_reservations/#{reservation.id}", headers: headers

    expect(response).to have_http_status(:no_content)
    expect(TableReservation.find_by(id: reservation.id)).to be_nil
    expect(table).to be_available_between(date, "11:30")
  end

  it "deactivates one reservation so the same slot can be booked again" do
    reservation = create(:table_reservation, table: table, reservation_date: date, start_time: "11:30")

    patch "/api/v1/admin/table_reservations/#{reservation.id}/deactivate", headers: headers, as: :json

    expect(response).to have_http_status(:ok)
    expect(json_body["active"]).to be(false)
    expect(table).to be_available_between(date, "11:30")

    replacement = build(:table_reservation, table: table, reservation_date: date, start_time: "11:30")
    expect(replacement).to be_valid
    expect(replacement.save).to be(true)
  end

  it "lets an admin change the dining window used for availability" do
    get "/api/v1/admin/table_reservations/estimated_duration", headers: headers

    expect(response).to have_http_status(:ok)
    expect(json_body).to include("estimated_duration_minutes" => 120, "slot_minutes" => 30)

    patch "/api/v1/admin/table_reservations/estimated_duration",
      params: { estimated_duration_minutes: 90 },
      headers: headers,
      as: :json

    expect(response).to have_http_status(:ok)
    expect(json_body["estimated_duration_minutes"]).to eq(90)

    reservation = create(:table_reservation, table: table, reservation_date: date, start_time: "11:30")
    expect(reservation.estimated_end_time.strftime("%H:%M")).to eq("13:00")
    expect(table).not_to be_available_between(date, "12:30")
    expect(table).to be_available_between(date, "13:00")
  end

  it "rejects a dining window that is not a 30-minute multiple" do
    patch "/api/v1/admin/table_reservations/estimated_duration",
      params: { estimated_duration_minutes: 45 },
      headers: headers,
      as: :json

    expect(response).to have_http_status(:unprocessable_entity)
    expect(TableReservation.estimated_duration).to eq(2.hours)
  end
end
