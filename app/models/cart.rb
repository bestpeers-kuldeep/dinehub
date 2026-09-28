class Cart < ApplicationRecord
  belongs_to :user
  has_many :cart_items, dependent: :destroy

  enum :status, { active: 0, completed: 1 }
  scope :active, -> { where(deleted_at: nil) }
end
