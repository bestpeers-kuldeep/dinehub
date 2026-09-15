class CreateEventItems < ActiveRecord::Migration[8.1]
  def change
    create_table :event_items do |t|
      t.string :title, null: false
      t.references :event, null: false, foreign_key: true
      t.text :description
      t.date :event_date, null: false
      t.time :start_time
      t.time :end_time

      t.timestamps
    end

    add_index :event_items, :event_date
  end
end
