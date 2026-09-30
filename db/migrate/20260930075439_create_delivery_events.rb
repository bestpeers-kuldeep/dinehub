class CreateDeliveryEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :delivery_events do |t|
      t.references :delivery, null: false, foreign_key: true
      t.string :event_type
      t.string :external_event_id
      t.jsonb :payload

      t.timestamps
    end
  end
end
