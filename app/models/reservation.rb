class Reservation < ApplicationRecord
  # Guests pick a 30-minute arrival slot. The table is held only for that slot
  # [start, start + 30 minutes), so 11:30 does not block 12:30 or 13:00.
  SLOT_MINUTES = 30
  ESTIMATED_DURATION = 2.hours

  belongs_to :table

  validates :reservation_date, presence: true
  validates :start_time, presence: true
  validates :first_name, :last_name, :email, :phone, presence: true
  validate :start_time_on_half_hour_slot
  validate :no_overlapping_reservation

  delegate :location, to: :table, allow_nil: true

  # Estimated leave time for availability checks only (not a DB column).
  def estimated_end_time
    parsed_start_time + ESTIMATED_DURATION
  end

  # Conflicts if another reservation's estimated window overlaps this one.
  # Existing start S overlaps [start, end) when
  # S < end AND S > start - ESTIMATED_DURATION.
  scope :overlapping, ->(date, start_time, end_time = nil) {
    start_at = coerce_time(start_time)
    end_at = end_time.present? ? coerce_time(end_time) : start_at + ESTIMATED_DURATION
    window_start = start_at - ESTIMATED_DURATION

    where(reservation_date: date)
      .where("start_time < ?", sql_time(end_at))
      .where("start_time > ?", sql_time(window_start))
  }

  def self.coerce_time(value)
    return value if value.acts_like?(:time)

    Time.zone.parse(value.to_s)
  end

  def self.sql_time(value)
    coerce_time(value).strftime("%H:%M:%S")
  end

  def as_public_json
    {
      id: id,
      location: location,
      reservation_date: reservation_date,
      start_time: parsed_start_time.strftime("%H:%M"),
      estimated_end_time: estimated_end_time.strftime("%H:%M"),
      first_name: first_name,
      last_name: last_name,
      email: email,
      phone: phone,
      occasion: occasion,
      special_requests: special_requests
    }
  end

  private

  def parsed_start_time
    self.class.coerce_time(start_time)
  end

  def start_time_on_half_hour_slot
    return if start_time.blank?

    time = parsed_start_time
    return if time.min % SLOT_MINUTES == 0 && time.sec == 0

    errors.add(:start_time, "must be on a #{SLOT_MINUTES}-minute slot")
  end

  def no_overlapping_reservation
    return if table.blank? || reservation_date.blank? || start_time.blank?

    overlap = table.reservations.overlapping(
      reservation_date,
      start_time,
      estimated_end_time
    )
    overlap = overlap.where.not(id: id) if persisted?
    return unless overlap.exists?

    errors.add(:base, "table is already booked around this arrival time")
  end
end
