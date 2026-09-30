require "rails_helper"

RSpec.describe DeliveryAddress, type: :model do
  let(:user) { create(:user) }

  it "requires the core address fields" do
    address = described_class.new(user: user)

    expect(address).not_to be_valid
    expect(address.errors.attribute_names).to include(:address_line, :city, :state, :postal_code)
  end

  it "validates coordinate ranges" do
    address = build(:delivery_address, user: user, latitude: 95, longitude: 200)

    expect(address).not_to be_valid
    expect(address.errors.attribute_names).to include(:latitude, :longitude)
  end

  it "accepts addresses without coordinates" do
    expect(build(:delivery_address, user: user, latitude: nil, longitude: nil)).to be_valid
  end

  describe "single default per user" do
    it "demotes the previous default when a new default is created" do
      old_default = create(:delivery_address, user: user, is_default: true)

      new_default = create(:delivery_address, user: user, is_default: true)

      expect(new_default.reload).to be_is_default
      expect(old_default.reload).not_to be_is_default
    end

    it "demotes the previous default when an existing address is promoted" do
      old_default = create(:delivery_address, user: user, is_default: true)
      other = create(:delivery_address, user: user)

      other.update!(is_default: true)

      expect(other.reload).to be_is_default
      expect(old_default.reload).not_to be_is_default
    end

    it "does not affect other users' defaults" do
      someone_else = create(:delivery_address, is_default: true)

      create(:delivery_address, user: user, is_default: true)

      expect(someone_else.reload).to be_is_default
    end

    it "leaves defaults alone when saving unrelated changes" do
      default = create(:delivery_address, user: user, is_default: true)
      other = create(:delivery_address, user: user)

      other.update!(landmark: "Near the park")

      expect(default.reload).to be_is_default
    end
  end

  it "detaches itself from orders when destroyed" do
    address = create(:delivery_address, user: user)
    order = create(:order, user: user, delivery_address: address)

    address.destroy!

    expect(order.reload.delivery_address_id).to be_nil
  end
end
