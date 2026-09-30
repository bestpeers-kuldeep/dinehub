class DeliveryEvent < ApplicationRecord
  belongs_to :delivery

  validates :event_type, presence: true
  # Provider webhooks are retried; the same external event must only be stored once.
  validates :external_event_id, uniqueness: { scope: :delivery_id }, allow_nil: true
end
