require "administrate/base_dashboard"

class AdministratorDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    first_name: Field::String,
    last_name: Field::String,
    email: Field::Email,
    password: Field::Password,
    password_confirmation: Field::Password,
    created_at: Field::DateTime,
    updated_at: Field::DateTime
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    id
    first_name
    last_name
    email
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id
    first_name
    last_name
    email
    created_at
    updated_at
  ].freeze

  FORM_ATTRIBUTES = %i[
    first_name
    last_name
    email
    password
    password_confirmation
  ].freeze

  COLLECTION_FILTERS = {}.freeze

  def display_resource(administrator)
    "#{administrator.first_name} #{administrator.last_name}"
  end
end
