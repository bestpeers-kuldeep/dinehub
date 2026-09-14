class CreateMenus < ActiveRecord::Migration[8.1]
  def change
    create_table :menus do |t|
      t.string :name, null: false
      t.integer :category_type, null: false, default: 0
      t.timestamps
    end
  end
end