class MenuItem < ApplicationRecord
  belongs_to :menu_category

  has_one_attached :photo

  delegate :drink_type, to: :menu_category, allow_nil: true

  scope :for_drink_type, ->(drink_type) {
    joins(:menu_category).where(menu_categories: { drink_type: drink_type })
  }
end
