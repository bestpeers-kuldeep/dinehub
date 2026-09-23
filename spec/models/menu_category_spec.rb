require "rails_helper"

RSpec.describe MenuCategory, type: :model do
  it "does not persist an image_url column" do
    expect(described_class.column_names).not_to include("image_url")
  end
end
