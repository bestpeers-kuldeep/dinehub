class MenuCategory < ApplicationRecord
  belongs_to :menu
  has_many :menu_items, dependent: :destroy
end
