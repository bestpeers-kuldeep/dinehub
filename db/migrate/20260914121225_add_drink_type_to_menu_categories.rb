class AddDrinkTypeToMenuCategories < ActiveRecord::Migration[8.1]
  def change
    add_column :menu_categories, :drink_type, :integer
  end
end
