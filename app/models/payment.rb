class Payment < ApplicationRecord
  belongs_to :order

  enum :status, {
    pending: 0,
    processing: 1,
    successful: 2,
    failed: 3,
    cancelled: 4
  }

  validates :gateway, presence: true
  validates :amount, numericality: { greater_than: 0 }
  validates :currency, presence: true
  # One payment row per order (Order has_one :payment); unique index on order_id.
  validates :order_id, uniqueness: true
  validates :gateway_order_id, uniqueness: { scope: :gateway }, allow_nil: true

  def terminal?
    successful? || failed? || cancelled?
  end
end
