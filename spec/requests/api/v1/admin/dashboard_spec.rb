require "rails_helper"

RSpec.describe "Admin dashboard API", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let(:headers) { auth_headers_for(create(:user, :admin)) }

  it "returns today's counts and a date range" do
    travel_to Time.zone.local(2026, 10, 9, 15, 0, 0) do
      today_customer = create(:user)
      another_customer = create(:user)
      create(:user)

      completed = create(:order, user: today_customer, status: :completed, subtotal: 30, total: 30)
      create(:payment, order: completed, status: :successful, amount: 30)
      create(:order, user: another_customer, status: :pending, subtotal: 10, total: 10)
      create(:order, status: :cancelled, subtotal: 50, total: 50, created_at: 5.days.ago)

      create(:table_reservation, reservation_date: Date.new(2026, 10, 9), start_time: "18:00")
      create(:table_reservation, reservation_date: Date.new(2026, 10, 1), start_time: "18:00")
      create(:table_reservation, reservation_date: Date.new(2026, 10, 9), start_time: "19:00", active: false)

      get "/api/v1/admin/dashboard", params: { from: "2026-10-01", to: "2026-10-09" }, headers: headers

      expect(response).to have_http_status(:ok)

      today = json_body.fetch("today")
      expect(today).to include("from" => "2026-10-09", "to" => "2026-10-09")
      expect(today["orders_by_status"]).to include("completed" => 1, "pending" => 1, "cancelled" => 0)
      expect(today["orders_total"]).to eq(2)
      expect(today["revenue"]).to eq("30.00")
      expect(today["reservations"]).to eq(1)
      expect(today["active_users"]).to eq(2)

      range = json_body.fetch("range")
      expect(range).to include("from" => "2026-10-01", "to" => "2026-10-09")
      expect(range["orders_by_status"]).to include("completed" => 1, "pending" => 1, "cancelled" => 1)
      expect(range["orders_total"]).to eq(3)
      expect(range["revenue"]).to eq("30.00")
      expect(range["reservations"]).to eq(2)
      expect(range["active_users"]).to eq(3)
    end
  end

  it "defaults the range to today" do
    travel_to Time.zone.local(2026, 10, 9, 15, 0, 0) do
      get "/api/v1/admin/dashboard", headers: headers

      expect(response).to have_http_status(:ok)
      expect(json_body["today"]).to include("from" => "2026-10-09", "to" => "2026-10-09", "revenue" => "0.00")
      expect(json_body["range"]).to include("from" => "2026-10-09", "to" => "2026-10-09")
    end
  end

  it "rejects a range that ends before it starts" do
    get "/api/v1/admin/dashboard", params: { from: "2026-10-09", to: "2026-10-01" }, headers: headers

    expect(response).to have_http_status(:unprocessable_entity)
    expect(json_body["errors"]).to include("from must be on or before to")
  end

  it "forbids customers" do
    get "/api/v1/admin/dashboard", headers: auth_headers_for(create(:user))

    expect(response).to have_http_status(:forbidden)
  end
end
