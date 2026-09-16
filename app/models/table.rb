class Table < ApplicationRecord
  enum :location, { 'Cocktail Bar': 0, 'Covered Patio': 1, 'Dining Room': 2, 'Snug': 3 }

  has_many :reservations, dependent: :destroy

  validates :name, presence: true, uniqueness: true
  validates :location, presence: true
  validates :capacity, presence: true, numericality: {
    only_integer: true,
    greater_than: 0,
    less_than: 20
  }
end
