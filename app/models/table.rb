class Table < ApplicationRecord
  enum :location, { "Cocktail Bar": 0, "Covered Patio": 1, "Dining Room": 2, "Snug": 3 }

  has_many :reservations, dependent: :destroy

  validates :name, presence: true, uniqueness: true
  validates :location, presence: true
  validates :capacity, presence: true, numericality: {
    only_integer: true,
    greater_than: 0,
    less_than: 20
  }

  def available_between?(date, start_time)
    reservations.overlapping(date, start_time).none?
  end

  def self.for_party(capacity)
    return all if capacity.blank?

    where("capacity >= ?", capacity)
  end

  # Must be called inside a transaction. Locks candidate tables in the location
  # so concurrent reservation creates cannot claim the same table.
  def self.lock_available_for(location:, date:, start_time:, capacity: nil)
    for_party(capacity)
      .where(location: location)
      .order(:id)
      .lock
      .to_a
      .find { |table| table.available_between?(date, start_time) }
  end

  def self.availability_by_location(date:, start_time:, location: nil, capacity: nil)
    scope = for_party(capacity)
    scope = scope.where(location: location) if location.present?

    booked_ids = Reservation.overlapping(date, start_time).select(:table_id)
    available_counts = scope.where.not(id: booked_ids).group(:location).count

    location_names = location.present? ? Array(location) : locations.keys
    location_names.map do |name|
      {
        location: name,
        available_tables: count_for_location(available_counts, name)
      }
    end
  end

  def self.count_for_location(counts, name)
    counts[name] || counts[name.to_s] || counts[locations[name]] || 0
  end
  private_class_method :count_for_location
end
