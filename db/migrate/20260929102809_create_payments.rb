class CreatePayments < ActiveRecord::Migration[8.1]
  def change
    create_table :payments do |t|
      t.references :order, null: false, foreign_key: true

      t.string :gateway, null: false
      t.string :gateway_order_id
      t.string :gateway_payment_id
      t.string :payment_session_id

      t.decimal :amount, precision: 12, scale: 2, null: false
      t.string :currency, null: false

      t.integer :status, null: false, default: 0

      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :payments, :gateway_order_id
    add_index :payments, [ :gateway, :gateway_order_id ], unique: true
  end
end
