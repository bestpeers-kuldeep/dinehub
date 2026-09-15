class AddImageUrlToMenuCategories < ActiveRecord::Migration[8.1]
  def change
    add_column :menu_categories, :image_url, :string
  end
end
