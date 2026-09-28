class CreateCartItems < ActiveRecord::Migration[8.1]
  def change
    create_table :cart_items do |t|
      t.references :cart, null: false, foreign_key: true
      t.references :menu_item, null: false, foreign_key: true
      t.integer :quantity
      t.decimal :unit_price

      t.timestamps
    end
    add_index :cart_items, [:cart_id, :menu_item_id], unique: true
  end
end
