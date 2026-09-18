require "test_helper"

class Api::V1::MenuItemsControllerTest < ActionDispatch::IntegrationTest
  test "index includes image_url for items with attached images" do
    item = menu_items(:one)
    item.image.attach(
      io: StringIO.new("fake-image"),
      filename: "bruschetta.jpg",
      content_type: "image/jpeg"
    )

    get "/api/v1/menu_items"

    assert_response :success
    body = JSON.parse(response.body)
    payload = body.find { |row| row["id"] == item.id }

    assert_equal item.reload.image_url, payload["image_url"]
  end
end
