class CreateDeliveries < ActiveRecord::Migration[8.1]
  def change
    create_table :deliveries do |t|
      t.references :order, null: false, foreign_key: true
      t.string :provider
      t.string :external_delivery_id
      t.string :tracking_number
      t.integer :status
      t.string :tracking_url
      t.string :rider_name
      t.string :rider_phone
      t.decimal :rider_latitude
      t.decimal :rider_longitude
      t.jsonb :metadata

      t.timestamps
    end
    add_index :deliveries,
          [ :provider, :external_delivery_id ],
          unique: true,
          where: "external_delivery_id IS NOT NULL"
  end
end
