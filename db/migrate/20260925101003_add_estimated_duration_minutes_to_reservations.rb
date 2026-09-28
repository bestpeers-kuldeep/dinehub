class AddEstimatedDurationMinutesToReservations < ActiveRecord::Migration[8.1]
  def change
    add_column :reservations, :estimated_duration_minutes, :integer, default: 120, null: false
  end
end
