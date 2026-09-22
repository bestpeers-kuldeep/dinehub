class Menu < ApplicationRecord
  has_many :menu_categories, dependent: :destroy

  validates :name, presence: true, uniqueness: true
end
