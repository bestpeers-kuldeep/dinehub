class Cart < ApplicationRecord
  belongs_to :user
  has_one :order
  has_many :cart_items, dependent: :destroy

  enum :status, { active: 0, completed: 1 }
  scope :active, -> { where(status: :active, deleted_at: nil) }
end
