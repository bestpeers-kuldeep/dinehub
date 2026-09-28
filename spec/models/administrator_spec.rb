require "rails_helper"

RSpec.describe Administrator, type: :model do
  it "requires first name, last name, email, and password" do
    administrator = described_class.new

    expect(administrator).not_to be_valid
    expect(administrator.errors[:first_name]).to include("can't be blank")
    expect(administrator.errors[:last_name]).to include("can't be blank")
    expect(administrator.errors[:email]).to include("can't be blank")
    expect(administrator.errors[:password]).to include("can't be blank")
  end

  it "normalizes email and enforces uniqueness" do
    create(:administrator, email: "  Admin@Example.com ")

    duplicate = build(:administrator, email: "ADMIN@example.com")

    expect(Administrator.last.email).to eq("admin@example.com")
    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:email]).to include("has already been taken")
  end

  it "authenticates with the given password" do
    administrator = build(:administrator, password: "password123")

    expect(administrator.authenticate("password123")).to be_truthy
    expect(administrator.authenticate("wrong-password")).to be_falsey
  end
end
