require "administrate/base_dashboard"

class UserDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    first_name: Field::String,
    last_name: Field::String,
    email: Field::Email,
    phone: Field::String,
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
    phone
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id
    first_name
    last_name
    email
    phone
    created_at
    updated_at
  ].freeze

  FORM_ATTRIBUTES = %i[
    first_name
    last_name
    email
    phone
    password
    password_confirmation
  ].freeze

  COLLECTION_FILTERS = {}.freeze

  def display_resource(user)
    "#{user.first_name} #{user.last_name}"
  end
end
