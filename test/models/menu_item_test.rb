require "test_helper"

class MenuItemTest < ActiveSupport::TestCase
  test "syncs image_url after an image is attached" do
    item = menu_items(:one)

    item.image.attach(
      io: StringIO.new("fake-image"),
      filename: "bruschetta.jpg",
      content_type: "image/jpeg"
    )

    item.reload
    assert item.image.attached?
    assert_not_nil item.image_url
    assert_match %r{/rails/active_storage/blobs/}, item.image_url
  end

  test "leaves image_url blank when no image is attached" do
    item = MenuItem.create!(
      name: "Plain Item",
      price: 5,
      menu_category: menu_categories(:one)
    )

    assert_nil item.reload.image_url
  end

  test "does not rewrite image_url when it already matches the blob url" do
    item = menu_items(:one)
    item.image.attach(
      io: StringIO.new("fake-image"),
      filename: "bruschetta.jpg",
      content_type: "image/jpeg"
    )
    item.reload
    original_url = item.image_url

    item.update!(description: "Updated description")

    assert_equal original_url, item.reload.image_url
  end
end
