require "rails_helper"

RSpec.describe InquiryReservationMailer, type: :mailer do
  before { ActionMailer::Base.deliveries.clear }

  it "sends a party inquiry received email" do
    reservation = build(
      :parties_reservation,
      id: 2101,
      special_requests: "Wheelchair access near the bar"
    )
    email = described_class.inquiry_received(reservation)

    expect { email.deliver_now }
      .to change(ActionMailer::Base.deliveries, :count).by(1)
    expect(email.to).to eq([reservation.email])
    expect(email.subject).to eq("We received your party inquiry")
    expect(email.html_part.body.to_s).to include("We've recorded your Party Request")
    expect(email.text_part.body.to_s).to include("Our team will contact you soon")
    expect(email.text_part.body.to_s).to include("Birthday")
    expect(email.text_part.body.to_s).to include("Wheelchair access near the bar")
  end

  it "sends a catering inquiry received email" do
    reservation = build(:catering_reservation, id: 3101, company: "Northwind")
    email = described_class.inquiry_received(reservation)

    expect { email.deliver_now }
      .to change(ActionMailer::Base.deliveries, :count).by(1)
    expect(email.to).to eq([reservation.email])
    expect(email.subject).to eq("We received your catering inquiry")
    expect(email.html_part.body.to_s).to include("We've recorded your Catering Request")
    expect(email.text_part.body.to_s).to include("Northwind")
    expect(email.text_part.body.to_s).to include("Our team will contact you soon")
  end
end
