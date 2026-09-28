require "rails_helper"

RSpec.describe "Admin tables", type: :request do
  let(:password) { "password123" }
  let!(:administrator) { create(:administrator, password: password) }

  def basic_auth
    {
      "HTTP_AUTHORIZATION" =>
        ActionController::HttpAuthentication::Basic.encode_credentials(
          administrator.email,
          password
        )
    }
  end

  it "creates and updates a table" do
    expect {
      post admin_tables_path,
        params: {
          table: {
            name: "Window 1",
            location: "Dining Room",
            capacity: 4
          }
        },
        headers: basic_auth
    }.to change(Table, :count).by(1)

    table = Table.find_by!(name: "Window 1")
    patch admin_table_path(table),
      params: { table: { capacity: 6 } },
      headers: basic_auth

    expect(response).to redirect_to(admin_table_path(table))
    expect(table.reload.capacity).to eq(6)
  end

  it "shows bookings when viewing a table" do
    table = create(:table)
    reservation = create(
      :table_reservation,
      table: table,
      reservation_date: Date.new(2026, 9, 25),
      start_time: "18:00"
    )

    get admin_table_path(table), headers: basic_auth

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(table.name)
    expect(response.body).to include(reservation.full_name)
  end

  it "updates the estimated duration of a booking" do
    reservation = create(:table_reservation, estimated_duration_minutes: 120)

    patch admin_table_reservation_path(reservation),
      params: {
        table_reservation: {
          table_id: reservation.table_id,
          reservation_date: reservation.reservation_date,
          start_time: reservation.start_time,
          estimated_duration_minutes: 90,
          full_name: reservation.full_name,
          email: reservation.email,
          phone: reservation.phone
        }
      },
      headers: basic_auth

    expect(response).to redirect_to(admin_table_reservation_path(reservation))
    expect(reservation.reload.estimated_duration_minutes).to eq(90)
  end
end
