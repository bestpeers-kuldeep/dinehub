class AddAdminTableReservationSettings < ActiveRecord::Migration[8.1]
  def change
    add_column :reservations, :active, :boolean, null: false, default: true

    remove_index :reservations, name: "index_reservations_on_table_date_start"
    add_index :reservations,
      [ :table_id, :reservation_date, :start_time ],
      unique: true,
      where: "table_id IS NOT NULL AND active = true",
      name: "index_reservations_on_table_date_start"

    create_table :settings do |t|
      t.string :key, null: false
      t.string :value, null: false

      t.timestamps
    end
    add_index :settings, :key, unique: true
  end
end
