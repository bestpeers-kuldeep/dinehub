class CreateMenuItems < ActiveRecord::Migration[8.1]
  def change
    create_table :menu_items do |t|
      t.references :menu_category, null: false, foreign_key: true
      t.string :name, null: false
      t.datetime :start_at
      t.datetime :end_at
      t.text :description
      t.decimal :price, precision: 10, scale: 2, null: false

      t.timestamps
    end

    add_index :menu_items, :name
  end
end
