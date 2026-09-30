class CreateDeliveryAddresses < ActiveRecord::Migration[8.1]
  def change
    create_table :delivery_addresses do |t|
      t.references :user, null: false, foreign_key: true
      t.text :address_line
      t.string :city
      t.string :state
      t.string :postal_code
      t.string :landmark
      t.decimal :latitude
      t.decimal :longitude
      t.boolean :is_default, default: false

      t.timestamps
    end
  end
end
