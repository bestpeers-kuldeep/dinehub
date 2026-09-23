require "rails_helper"

RSpec.describe InquiryReservations::Create, type: :service do
  it "creates a parties reservation" do
    reservation = described_class.call(
      reservation_class: PartiesReservation,
      attributes: attributes_for(:parties_reservation, marketing_opt_in: true)
    )

    expect(reservation).to be_a(PartiesReservation)
    expect(reservation.full_name).to eq("Alex Guest")
    expect(reservation.marketing_opt_in).to be(true)
    expect(reservation.table_id).to be_nil
  end

  it "creates a catering reservation" do
    reservation = described_class.call(
      reservation_class: CateringReservation,
      attributes: attributes_for(:catering_reservation, company: "Northwind")
    )

    expect(reservation).to be_a(CateringReservation)
    expect(reservation.company).to eq("Northwind")
  end

  it "combines first and last name when full_name is omitted" do
    attributes = attributes_for(:parties_reservation)
      .except(:full_name)
      .merge(first_name: "Sam", last_name: "Taylor")

    reservation = described_class.call(
      reservation_class: PartiesReservation,
      attributes: attributes
    )

    expect(reservation.full_name).to eq("Sam Taylor")
  end

  it "raises when required fields are missing" do
    attributes = attributes_for(:parties_reservation).slice(:email, :phone)

    expect do
      described_class.call(
        reservation_class: PartiesReservation,
        attributes: attributes
      )
    end.to raise_error(ActiveRecord::RecordInvalid)
  end
end
