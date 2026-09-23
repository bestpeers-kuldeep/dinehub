require "rails_helper"

RSpec.describe User, type: :model do
  it "requires first name, last name, email, phone, and password" do
    user = described_class.new

    expect(user).not_to be_valid
    expect(user.errors[:first_name]).to include("can't be blank")
    expect(user.errors[:last_name]).to include("can't be blank")
    expect(user.errors[:email]).to include("can't be blank")
    expect(user.errors[:phone]).to include("can't be blank")
    expect(user.errors[:password]).to include("can't be blank")
  end

  it "normalizes email and enforces uniqueness" do
    create(:user, email: "  Sam@Example.com ")

    duplicate = build(:user, email: "SAM@example.com")

    expect(User.last.email).to eq("sam@example.com")
    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:email]).to include("has already been taken")
  end

  it "authenticates with the given password" do
    user = build(:user, password: "password123")

    expect(user.authenticate("password123")).to be_truthy
    expect(user.authenticate("wrong-password")).to be_falsey
  end

  it "stores a hashed reset token and enqueues a reset email" do
    user = create(:user)

    expect {
      raw_token = user.send_reset_password_instructions
      expect(raw_token).to be_present
      expect(user.reload.reset_password_token).to eq(Digest::SHA256.hexdigest(raw_token))
      expect(user.reset_password_sent_at).to be_present
    }.to have_enqueued_mail(UserMailer, :reset_password_instructions)
  end

  it "updates the password digest from a valid reset token" do
    user = create(:user, password: "password123")
    raw_token = user.send_reset_password_instructions

    user.reset_password!(password: "newpass123")
    user.reload

    expect(user.authenticate("newpass123")).to be_truthy
    expect(user.authenticate("password123")).to be_falsey
    expect(user.reset_password_token).to be_nil
    expect(user.reset_password_sent_at).to be_nil
    expect(User.find_by_reset_password_token(raw_token)).to be_nil
  end
end
