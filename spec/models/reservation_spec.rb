require "rails_helper"

RSpec.describe Reservation, type: :model do
  let(:table) { create(:table) }
  let(:date) { Date.new(2026, 9, 16) }

  it "holds the table for two hours from the 11:30 slot" do
    reservation = create(
      :table_reservation,
      table: table,
      reservation_date: date,
      start_time: "11:30"
    )

    expect(reservation.estimated_end_time.strftime("%H:%M")).to eq("13:30")
    expect(table).not_to be_available_between(date, "11:30")
    expect(table).not_to be_available_between(date, "12:00")
    expect(table).not_to be_available_between(date, "12:30")
    expect(table).not_to be_available_between(date, "13:00")
    expect(table).to be_available_between(date, "13:30")
  end

  it "rejects a second booking in the same 30-minute slot" do
    create(:table_reservation, table: table, reservation_date: date, start_time: "11:30")
    overlap = build(
      :table_reservation,
      table: table,
      reservation_date: date,
      start_time: "11:30"
    )

    expect(overlap).not_to be_valid
    expect(overlap.errors[:base]).to include("table is already booked around this arrival time")
  end

  it "allows a slot after the two-hour window on the same table" do
    create(:table_reservation, table: table, reservation_date: date, start_time: "11:30")
    later = build(
      :table_reservation,
      table: table,
      reservation_date: date,
      start_time: "13:30"
    )

    expect(later).to be_valid
  end

  it "enqueues a confirmation email after the reservation is saved" do
    expect do
      create(:table_reservation, table: table, reservation_date: date, start_time: "11:30")
    end.to have_enqueued_mail(TableReservationMailer, :reservation_confirmation)
  end

  it "does not enqueue email when the reservation is invalid" do
    reservation = build(
      :table_reservation,
      table: table,
      reservation_date: date,
      start_time: "11:15"
    )

    expect { reservation.save }
      .not_to have_enqueued_mail(TableReservationMailer, :reservation_confirmation)
    expect(reservation).not_to be_persisted
  end

  it "rejects start times that are not 30-minute slots" do
    reservation = build(
      :table_reservation,
      table: table,
      reservation_date: date,
      start_time: "11:15"
    )

    expect(reservation).not_to be_valid
    expect(reservation.errors[:start_time]).to include("must be on a 30-minute slot")
  end
end
