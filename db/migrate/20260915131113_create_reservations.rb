class CreateReservations < ActiveRecord::Migration[8.1]
  def change
    create_table :reservations do |t|
      t.references :table, null: false, foreign_key: true
      t.date :reservation_date, null: false
      t.time :start_time, null: false
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :email, null: false
      t.string :phone, null: false
      t.integer :occasion
      t.text :special_requests

      t.timestamps
    end

    add_index :reservations, [ :table_id, :reservation_date ]
    add_index :reservations, [ :table_id, :reservation_date, :start_time ], unique: true, name: "index_reservations_on_table_date_start"
  end
end
