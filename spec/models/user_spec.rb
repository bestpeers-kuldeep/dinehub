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
end
