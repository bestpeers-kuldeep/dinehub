class CreateCarts < ActiveRecord::Migration[8.1]
  def change
    create_table :carts do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :status, null: false, default: 0
      t.datetime :deleted_at

      t.timestamps
    end
  end
end
