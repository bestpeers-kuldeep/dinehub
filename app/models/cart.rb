class Cart < ApplicationRecord
  belongs_to :user
  # A cart can produce another order after an earlier one is cancelled.
  has_many :orders
  has_many :payments, dependent: :destroy
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

  def checkout_in_progress?
    payments.open_checkout.exists?
  end

  def ensure_editable!
    return unless checkout_in_progress?

    raise Orders::Errors::CartNotEditable, "Cart is checked out and cannot be changed"
  end

  # A payment session is bound to the previous total. Once the cart changes,
  # that checkout is cancelled so the next payment uses the current total.
  def refresh_open_checkout!
    payment = payments.open_checkout.first
    return if payment.nil? || payment.payment_session_id.blank?

    items = cart_items.to_a
    total = Payment.total_for(items)
    return if total.positive? && payment.checkout_current?(items, total)

    payment.abandon_for_cart_change!
  end
end
