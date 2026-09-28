require "administrate/base_dashboard"

class TableReservationDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    table: Field::BelongsTo,
    reservation_date: Field::Date,
    start_time: Field::Time,
    estimated_duration_minutes: Field::Number,
    full_name: Field::String,
    email: Field::Email,
    phone: Field::String,
    number_of_people: Field::Number,
    occasion: Field::String,
    special_requests: Field::Text,
    marketing_opt_in: Field::Boolean,
    created_at: Field::DateTime,
    updated_at: Field::DateTime
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    id
    table
    reservation_date
    start_time
    full_name
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id
    table
    reservation_date
    start_time
    estimated_duration_minutes
    full_name
    email
    phone
    number_of_people
    occasion
    special_requests
    marketing_opt_in
    created_at
    updated_at
  ].freeze

  FORM_ATTRIBUTES = %i[
    table
    reservation_date
    start_time
    estimated_duration_minutes
    full_name
    email
    phone
    number_of_people
    occasion
    special_requests
    marketing_opt_in
  ].freeze

  COLLECTION_FILTERS = {}.freeze

  def display_resource(reservation)
    "#{reservation.full_name} — #{reservation.reservation_date} #{reservation.parsed_start_time.strftime('%H:%M')}"
  end
end
