class TableReservation < Reservation
  # Guests pick a 30-minute arrival slot. The table is held for a dining
  # window starting at that slot. Admins can change the window; 2 hours is
  # the default when no setting has been saved.
  SLOT_MINUTES = 30
  DEFAULT_ESTIMATED_DURATION = 2.hours
  MAX_ESTIMATED_DURATION_MINUTES = 12.hours.in_minutes.to_i
  DURATION_SETTING_KEY = "table_reservation.estimated_duration_minutes"

  belongs_to :table

  validates :reservation_date, presence: true
  validates :start_time, presence: true
  validates :full_name, presence: true
  validate :start_time_on_half_hour_slot
  validate :no_overlapping_reservation

  delegate :location, to: :table, allow_nil: true

  after_create_commit :send_reservation_confirmation_email

  def self.estimated_duration
    minutes = Setting.fetch(DURATION_SETTING_KEY)
    return DEFAULT_ESTIMATED_DURATION if minutes.blank?

    minutes.to_i.minutes
  end

  def self.assign_estimated_duration!(minutes)
    parsed = Integer(minutes, exception: false)
    if parsed.nil? || parsed <= 0 || parsed > MAX_ESTIMATED_DURATION_MINUTES || (parsed % SLOT_MINUTES).nonzero?
      raise ArgumentError, "estimated duration must be a positive multiple of #{SLOT_MINUTES} minutes up to #{MAX_ESTIMATED_DURATION_MINUTES}"
    end

    Setting.assign!(DURATION_SETTING_KEY, parsed)
    estimated_duration
  end

  # Estimated leave time for availability checks only (not a DB column).
  def estimated_end_time
    parsed_start_time + self.class.estimated_duration
  end

  scope :active, -> { where(active: true) }

  scope :overlapping, ->(date, start_time, end_time = nil) {
    duration = TableReservation.estimated_duration
    start_at = coerce_time(start_time)
    end_at = end_time.present? ? coerce_time(end_time) : start_at + duration
    window_start = start_at - duration

    active
      .where(reservation_date: date)
      .where("start_time < ?", sql_time(end_at))
      .where("start_time > ?", sql_time(window_start))
  }

  def send_reservation_confirmation_email
    TableReservationMailer.reservation_confirmation(self).deliver_later
  end

  def as_public_json
    {
      id: id,
      type: type,
      location: location,
      reservation_date: reservation_date,
      start_time: parsed_start_time.strftime("%H:%M"),
      estimated_end_time: estimated_end_time.strftime("%H:%M"),
      number_of_people: number_of_people,
      full_name: full_name,
      email: email,
      phone: phone,
      occasion: occasion,
      special_requests: special_requests,
      marketing_opt_in: marketing_opt_in
    }
  end

  def as_admin_json
    as_public_json.merge(
      table_id: table_id,
      table_name: table&.name,
      active: active,
      estimated_duration_minutes: self.class.estimated_duration.in_minutes.to_i
    )
  end

  private

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
