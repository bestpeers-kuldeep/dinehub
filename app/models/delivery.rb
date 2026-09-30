class Delivery < ApplicationRecord
  belongs_to :order

  has_many :delivery_events, dependent: :destroy

  enum :status, {
    pending: 0,
    requested: 1,
    assigned: 2,
    picked_up: 3,
    out_for_delivery: 4,
    delivered: 5,
    cancelled: 6,
    failed: 7
  }

  validates :status, presence: true
  # One delivery per order (Order has_one :delivery); unique index on order_id.
  validates :order_id, uniqueness: true
  validates :external_delivery_id, uniqueness: { scope: :provider }, allow_nil: true
end
