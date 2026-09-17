class AddStiToReservations < ActiveRecord::Migration[8.1]
  def up
    add_column :reservations, :type, :string, null: false, default: "TableReservation"
    add_index :reservations, :type

    change_column_null :reservations, :table_id, true
    change_column :reservations, :occasion, :string
    add_column :reservations, :full_name, :string
    add_column :reservations, :company, :string
    add_column :reservations, :duration, :string
    add_column :reservations, :budget_per_person, :decimal, precision: 10, scale: 2
    add_column :reservations, :description, :text
    add_column :reservations, :source, :string
    add_column :reservations, :number_of_people, :integer
    add_column :reservations, :marketing_opt_in, :boolean, null: false, default: false

    if column_exists?(:reservations, :first_name)
      execute <<~SQL.squish
        UPDATE reservations
        SET full_name = TRIM(BOTH FROM CONCAT_WS(' ', first_name, last_name))
        WHERE full_name IS NULL
      SQL

      remove_column :reservations, :first_name
      remove_column :reservations, :last_name
    end

    remove_index :reservations, name: "index_reservations_on_table_date_start"
    add_index :reservations,
      [ :table_id, :reservation_date, :start_time ],
      unique: true,
      where: "table_id IS NOT NULL",
      name: "index_reservations_on_table_date_start"
  end

  def down
    remove_index :reservations, name: "index_reservations_on_table_date_start"
    add_index :reservations,
      [ :table_id, :reservation_date, :start_time ],
      unique: true,
      name: "index_reservations_on_table_date_start"

    add_column :reservations, :first_name, :string
    add_column :reservations, :last_name, :string

    if column_exists?(:reservations, :full_name)
      execute <<~SQL.squish
        UPDATE reservations
        SET first_name = COALESCE(NULLIF(SPLIT_PART(full_name, ' ', 1), ''), 'Guest'),
            last_name = COALESCE(
              NULLIF(TRIM(SUBSTRING(full_name FROM POSITION(' ' IN full_name))), ''),
              first_name
            )
      SQL
    end

    change_column_null :reservations, :first_name, false
    change_column_null :reservations, :last_name, false
    change_column :reservations, :occasion, :integer

    remove_column :reservations, :full_name if column_exists?(:reservations, :full_name)
    remove_column :reservations, :company if column_exists?(:reservations, :company)
    remove_column :reservations, :duration if column_exists?(:reservations, :duration)
    remove_column :reservations, :budget_per_person if column_exists?(:reservations, :budget_per_person)
    remove_column :reservations, :description if column_exists?(:reservations, :description)
    remove_column :reservations, :source if column_exists?(:reservations, :source)
    remove_column :reservations, :number_of_people if column_exists?(:reservations, :number_of_people)
    remove_column :reservations, :marketing_opt_in if column_exists?(:reservations, :marketing_opt_in)

    execute "DELETE FROM reservations WHERE table_id IS NULL"
    change_column_null :reservations, :table_id, false

    remove_index :reservations, :type if index_exists?(:reservations, :type)
    remove_column :reservations, :type if column_exists?(:reservations, :type)
  end
end
