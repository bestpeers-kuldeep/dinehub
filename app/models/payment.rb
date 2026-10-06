class Payment < ApplicationRecord
  belongs_to :cart
  belongs_to :order, optional: true
  belongs_to :delivery_address, optional: true

  enum :status, {
    pending: 0,
    processing: 1,
    successful: 2,
    failed: 3,
    cancelled: 4
  }

  # Checkout rows have no order until the payment webhook creates one.
  scope :open_checkout, -> { where(order_id: nil, status: [ :pending, :processing ]) }

  validates :gateway, presence: true
  validates :amount, numericality: { greater_than: 0 }
  validates :currency, presence: true
  # One payment row per order (Order has_one :payment); unique index on order_id.
  validates :order_id, uniqueness: true, allow_nil: true
  validates :gateway_order_id, uniqueness: { scope: :gateway }, allow_nil: true

  def terminal?
    successful? || failed? || cancelled?
  end
end
