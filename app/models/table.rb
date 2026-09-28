class Table < ApplicationRecord
  enum :location, { "Cocktail Bar": 0, "Covered Patio": 1, "Dining Room": 2, "Snug": 3 }

  has_many :reservations, class_name: "TableReservation", dependent: :destroy

  validates :name, presence: true, uniqueness: true
  validates :location, presence: true
  validates :capacity, presence: true, numericality: {
    only_integer: true,
    greater_than: 0,
    less_than: 20
  }

  # scope :available,

  def available_between?(date, start_time, duration_minutes: TableReservation::DEFAULT_ESTIMATED_DURATION_MINUTES)
    end_time = Reservation.coerce_time(start_time) + duration_minutes.to_i.minutes
    reservations.overlapping(date, start_time, end_time).none?
  end

  def self.for_party(capacity)
    return all if capacity.blank?

    where("capacity >= ?", capacity)
  end

  # Must be called inside a transaction. Locks candidate tables in the location
  # so concurrent reservation creates cannot claim the same table.
  def self.lock_available_for(
    location:,
    date:,
    start_time:,
    capacity: nil,
    duration_minutes: TableReservation::DEFAULT_ESTIMATED_DURATION_MINUTES
  )
    for_party(capacity)
      .where(location: location)
      .order(:id)
      .lock
      .to_a
      .find do |table|
        table.available_between?(date, start_time, duration_minutes: duration_minutes)
      end
  end

  def self.availability_by_location(
    date:,
    start_time:,
    location: nil,
    capacity: nil,
    duration_minutes: TableReservation::DEFAULT_ESTIMATED_DURATION_MINUTES
  )
    scope = for_party(capacity)
    scope = scope.where(location: location) if location.present?

    end_time = Reservation.coerce_time(start_time) + duration_minutes.to_i.minutes
    booked_ids = TableReservation.overlapping(date, start_time, end_time).select(:table_id)
    available_counts = scope.where.not(id: booked_ids).group(:location).count

    location_names = location.present? ? Array(location) : locations.keys
    location_names.map do |name|
      {
        location: name,
        available_tables: count_for_location(available_counts, name)
      }
    end
  end

  def self.availability_details(
    date:,
    start_time:,
    location: nil,
    capacity: nil,
    duration_minutes: TableReservation::DEFAULT_ESTIMATED_DURATION_MINUTES
  )
    scope = for_party(capacity).order(:location, :name)
    scope = scope.where(location: location) if location.present?
    end_time = Reservation.coerce_time(start_time) + duration_minutes.to_i.minutes
    bookings = TableReservation
      .overlapping(date, start_time, end_time)
      .where(table_id: scope.select(:id))
      .index_by(&:table_id)

    scope.map do |table|
      booking = bookings[table.id]
      {
        id: table.id,
        name: table.name,
        location: table.location,
        capacity: table.capacity,
        status: booking.present? ? "booked" : "available",
        booked_from: booking&.parsed_start_time&.strftime("%H:%M"),
        booked_until: booking&.estimated_end_time&.strftime("%H:%M")
      }
    end
  end

  def self.count_for_location(counts, name)
    counts[name] || counts[name.to_s] || counts[locations[name]] || 0
  end
  private_class_method :count_for_location
end
