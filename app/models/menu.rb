class Menu < ApplicationRecord
  has_many :menu_categories, dependent: :destroy

  enum :category_type, { our_menu: 0, specials: 1, drinks: 2 }
end
