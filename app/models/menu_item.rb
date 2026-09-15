class MenuItem < ApplicationRecord
  belongs_to :menu_category

  

  delegate :drink_type, to: :menu_category, allow_nil: true

  scope :for_drink_type, ->(drink_type) {
    joins(:menu_category).where(menu_categories: { drink_type: drink_type })
  }

  # Items whose [start_at, end_at] overlaps the given date range (inclusive).
  # NULL bounds are treated as open-ended.
  scope :active_between, ->(start_date, end_date) {
    where(
      "(start_at IS NULL OR start_at::date <= ?) AND (end_at IS NULL OR end_at::date >= ?)",
      end_date, start_date
    )
  }
end
