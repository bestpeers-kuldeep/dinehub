require "test_helper"

class MenuCategoryTest < ActiveSupport::TestCase
  test "does not persist an image_url column" do
    assert_not MenuCategory.column_names.include?("image_url")
  end
end
