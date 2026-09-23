require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "requires first_name last_name email phone and password" do
    user = User.new
    assert_not user.valid?
    assert_includes user.errors[:first_name], "can't be blank"
    assert_includes user.errors[:last_name], "can't be blank"
    assert_includes user.errors[:email], "can't be blank"
    assert_includes user.errors[:phone], "can't be blank"
    assert_includes user.errors[:password], "can't be blank"
  end

  test "normalizes email and enforces uniqueness" do
    user = User.create!(
      first_name: "Sam",
      last_name: "Diner",
      email: "  Sam@Example.com ",
      phone: "555-0200",
      password: "password123"
    )

    assert_equal "sam@example.com", user.email
    duplicate = User.new(
      first_name: "Other",
      last_name: "Person",
      email: "SAM@example.com",
      phone: "555-0201",
      password: "password123"
    )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:email], "has already been taken"
  end

  test "authenticates with the given password" do
    user = users(:alex)
    assert user.authenticate("password123")
    assert_not user.authenticate("wrong-password")
  end
end
