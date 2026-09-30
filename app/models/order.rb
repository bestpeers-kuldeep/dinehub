class Order < ApplicationRecord
  belongs_to :user
  belongs_to :cart
  belongs_to :delivery_address, optional: true

  has_many :order_items, dependent: :destroy
  has_one :payment, dependent: :destroy
  has_one :delivery, dependent: :destroy

  enum :status, {
    pending: 0,
    confirmed: 1,
    preparing: 2,
    ready: 3,
    completed: 4,
    cancelled: 5
  }

  validates :subtotal, :total, numericality: { greater_than_or_equal_to: 0 }
  scope :active, -> { where.not(status: [ :completed, :cancelled ]) }
end
