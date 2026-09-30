class DeliveryAddress < ApplicationRecord
  belongs_to :user

  validates :address_line, :city, :state, :postal_code, presence: true
end
