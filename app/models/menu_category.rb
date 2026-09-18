class MenuCategory < ApplicationRecord
  belongs_to :menu
  has_many :menu_items, dependent: :destroy

  enum :drink_type, { beer: 0, wine: 1, cocktails: 2, spirits: 3, whiskey: 4 }, allow_nil: true
end
