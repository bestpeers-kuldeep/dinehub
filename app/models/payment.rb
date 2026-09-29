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
end
