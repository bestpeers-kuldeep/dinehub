class Cart < ApplicationRecord
  belongs_to :user
  # A cart can produce another order after an earlier one is cancelled.
  has_many :orders
  has_many :cart_items, dependent: :destroy

  enum :status, { active: 0, completed: 1 }
  scope :active, -> { where(status: :active, deleted_at: nil) }

  # A user has at most one live cart; the controllers rely on `carts.active.first`.
  # Backed by a partial unique index on carts(user_id) WHERE status = 0 AND deleted_at IS NULL.
  validates :user_id,
            uniqueness: { conditions: -> { active }, message: "already has an active cart" },
            if: :live?

  def live?
    active? && deleted_at.nil?
  end
end
