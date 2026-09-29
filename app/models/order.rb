class Order < ApplicationRecord
  belongs_to :user

  has_many :order_items, dependent: :destroy
  has_one :payment, dependent: :destroy

  enum :status, {
    pending: 0,
    confirmed: 1,
    preparing: 2,
    ready: 3,
    completed: 4,
    cancelled: 5
  }

  validates :subtotal, :total, numericality: { greater_than_or_equal_to: 0 }
end
