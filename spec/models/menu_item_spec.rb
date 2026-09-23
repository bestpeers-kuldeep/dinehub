require "rails_helper"

RSpec.describe MenuItem, type: :model do
  it "syncs image_url after an image is attached" do
    item = create(:menu_item, :with_image, image_filename: "bruschetta.jpg")

    expect(item.reload.image).to be_attached
    expect(item.image_url).to be_present
    expect(item.image_url).to match(%r{/rails/active_storage/blobs/})
  end

  it "leaves image_url blank when no image is attached" do
    item = create(:menu_item, name: "Plain Item", price: 5)

    expect(item.reload.image_url).to be_nil
  end

  it "does not rewrite image_url when it already matches the blob URL" do
    item = create(:menu_item, :with_image, image_filename: "bruschetta.jpg")
    original_url = item.reload.image_url

    item.update!(description: "Updated description")

    expect(item.reload.image_url).to eq(original_url)
  end
end
