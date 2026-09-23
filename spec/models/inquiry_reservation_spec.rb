require "rails_helper"

RSpec.describe InquiryReservation, type: :model do
  it "creates a parties reservation without a dining table" do
    reservation = create(:parties_reservation)

    expect(reservation.type).to eq("PartiesReservation")
    expect(reservation.table_id).to be_nil
    expect(reservation.full_name).to eq("Alex Guest")
  end

  it "creates a catering reservation without a dining table" do
    reservation = create(:catering_reservation, company: "Northwind")

    expect(reservation.type).to eq("CateringReservation")
    expect(reservation.table_id).to be_nil
  end

  it "enqueues a party inquiry email after create" do
    expect { create(:parties_reservation) }
      .to have_enqueued_mail(InquiryReservationMailer, :inquiry_received)
  end

  it "enqueues a catering inquiry email after create" do
    expect { create(:catering_reservation) }
      .to have_enqueued_mail(InquiryReservationMailer, :inquiry_received)
  end

  it "does not enqueue email when the inquiry is invalid" do
    reservation = build(
      :parties_reservation,
      full_name: nil,
      duration: nil,
      budget_per_person: nil
    )

    expect { reservation.save }
      .not_to have_enqueued_mail(InquiryReservationMailer, :inquiry_received)
    expect(reservation).not_to be_persisted
  end

  it "requires inquiry fields" do
    reservation = build(
      :parties_reservation,
      full_name: nil,
      duration: nil,
      budget_per_person: nil
    )

    expect(reservation).not_to be_valid
    expect(reservation.errors[:full_name]).to include("can't be blank")
    expect(reservation.errors[:duration]).to include("can't be blank")
    expect(reservation.errors[:budget_per_person]).to include("can't be blank")
  end
end
