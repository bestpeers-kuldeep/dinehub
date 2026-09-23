require "rails_helper"

RSpec.describe UserMailer, type: :mailer do
  before { ActionMailer::Base.deliveries.clear }

  it "sends password reset instructions" do
    user = build(:user, first_name: "Alex", email: "alex@example.com")
    raw_token = "reset-token-abc"
    email = described_class.reset_password_instructions(user, raw_token)

    expect { email.deliver_now }
      .to change(ActionMailer::Base.deliveries, :count).by(1)
    expect(email.to).to eq([ "alex@example.com" ])
    expect(email.subject).to eq("Reset your DineHub password")
    expect(email.html_part.body.to_s).to include("Reset your password")
    expect(email.html_part.body.to_s).to include("reset-password?token=#{raw_token}")
    expect(email.text_part.body.to_s).to include("Hi Alex")
    expect(email.text_part.body.to_s).to include("reset-password?token=#{raw_token}")
  end
end
