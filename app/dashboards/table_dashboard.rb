require "administrate/base_dashboard"

class TableDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    name: Field::String,
    location: Field::Select.with_options(
      searchable: false,
      collection: ->(field) { field.resource.class.locations.keys }
    ),
    capacity: Field::Number,
    reservations: Field::HasMany,
    created_at: Field::DateTime,
    updated_at: Field::DateTime
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    id
    name
    location
    capacity
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id
    name
    location
    capacity
    reservations
    created_at
    updated_at
  ].freeze

  FORM_ATTRIBUTES = %i[
    name
    location
    capacity
  ].freeze

  COLLECTION_FILTERS = {}.freeze

  def display_resource(table)
    table.name
  end
end
