class CreateTables < ActiveRecord::Migration[8.1]
  def change
    create_table :tables do |t|
      t.string :name, null: false
      t.integer :capacity, null: false
      t.integer :location, null: false

      t.timestamps
    end

    add_index :tables, :name, unique: true
    add_index :tables, :location
  end
end
