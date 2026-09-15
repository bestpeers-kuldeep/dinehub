class Event < ApplicationRecord
  has_many :event_items, dependent: :destroy

  validates :name, presence: true
end
