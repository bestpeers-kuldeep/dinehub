require "test_helper"

class MenuTest < ActiveSupport::TestCase
  test "is invalid without a name" do
    menu = Menu.new(name: "")

    assert_not menu.valid?
    assert_includes menu.errors[:name], "can't be blank"
  end

  test "is invalid with a duplicate name" do
    menu = Menu.new(name: menus(:one).name)

    assert_not menu.valid?
    assert_includes menu.errors[:name], "has already been taken"
  end
end
