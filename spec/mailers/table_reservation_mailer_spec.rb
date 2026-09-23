require "rails_helper"

RSpec.describe TableReservationMailer, type: :mailer do
  before { ActionMailer::Base.deliveries.clear }

  it "sends a reservation confirmation" do
    reservation = build(
      :table_reservation,
      table: build(:table, location: "Cocktail Bar"),
      start_time: "11:30"
    )
    email = described_class.reservation_confirmation(reservation)

    expect { email.deliver_now }
      .to change(ActionMailer::Base.deliveries, :count).by(1)
    expect(email.to).to eq([reservation.email])
    expect(email.subject).to eq("Reservation Confirmation")
    expect(email.html_part.body.to_s).to include(reservation.full_name)
    expect(email.text_part.body.to_s).to include("Cocktail Bar")
    expect(email.text_part.body.to_s).to include("11:30")
  end
end
