class RemoveCategoryTypeToMenus < ActiveRecord::Migration[8.1]
  def change
    remove_column :menus, :category_type, :integer
    add_index :menus, :name, unique: true
  end
end
