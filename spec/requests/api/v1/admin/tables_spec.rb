require "rails_helper"

RSpec.describe "Admin tables API", type: :request do
  let(:headers) { auth_headers_for(create(:user, :admin)) }
  let(:date) { Date.new(2026, 9, 16) }

  it "creates and updates a table" do
    post "/api/v1/admin/tables",
      params: { table: { name: "Window 1", capacity: 4, location: "Snug" } },
      headers: headers,
      as: :json

    expect(response).to have_http_status(:created)
    table_id = json_body.fetch("id")
    expect(json_body).to include(
      "name" => "Window 1",
      "location" => "Snug",
      "capacity" => 4,
      "available" => true,
      "active_reservations_count" => 0
    )

    patch "/api/v1/admin/tables/#{table_id}",
      params: { name: "Window 2", capacity: 6 },
      headers: headers,
      as: :json

    expect(response).to have_http_status(:ok)
    expect(json_body).to include("name" => "Window 2", "capacity" => 6)
    expect(Table.find(table_id).location).to eq("Snug")
  end

  it "rejects a table that cannot be seated" do
    post "/api/v1/admin/tables",
      params: { name: "Too Big", capacity: 20, location: "Cocktail Bar" },
      headers: headers,
      as: :json

    expect(response).to have_http_status(:unprocessable_entity)
    expect(json_body["errors"]).to include("Capacity must be less than 20")
  end

  it "lists tables with availability for the requested slot" do
    booked = create(:table, name: "Booked", location: "Cocktail Bar")
    open_table = create(:table, name: "Open", location: "Cocktail Bar")
    create(:table_reservation, table: booked, reservation_date: date, start_time: "11:30")

    get "/api/v1/admin/tables",
      params: { date: date, start_time: "11:30", per_page: 1, page: 1 },
      headers: headers

    expect(response).to have_http_status(:ok)
    expect(json_body.dig("pagination", "per_page")).to eq(1)
    expect(json_body.dig("pagination", "total_count")).to eq(2)
    expect(json_body.fetch("data").size).to eq(1)

    get "/api/v1/admin/tables",
      params: { date: date, start_time: "11:30", per_page: 10 },
      headers: headers

    rows = json_body.fetch("data").index_by { |row| row["id"] }
    expect(rows[booked.id]).to include("available" => false, "active_reservations_count" => 1)
    expect(rows[open_table.id]).to include("available" => true, "active_reservations_count" => 0)
  end

  it "marks a booked table available and frees that sitting" do
    table = create(:table, location: "Cocktail Bar")
    reservation = create(:table_reservation, table: table, reservation_date: date, start_time: "11:30")

    patch "/api/v1/admin/tables/#{table.id}/mark_available",
      params: { date: date, start_time: "11:30" },
      headers: headers,
      as: :json

    expect(response).to have_http_status(:ok)
    expect(json_body).to include("available" => true, "released_count" => 1, "active_reservations_count" => 0)
    expect(reservation.reload.active).to be(false)

    get "/api/v1/tables", params: { date: date, start_time: "11:30", location: "Cocktail Bar" }

    expect(json_body.fetch("locations").first["available_tables"]).to eq(1)
  end

  it "forbids customers from managing tables" do
    get "/api/v1/admin/tables", headers: auth_headers_for(create(:user))

    expect(response).to have_http_status(:forbidden)
  end
end
