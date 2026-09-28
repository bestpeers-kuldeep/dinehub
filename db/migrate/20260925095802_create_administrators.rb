class CreateAdministrators < ActiveRecord::Migration[8.1]
  def change
    create_table :administrators do |t|
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :email, null: false
      t.string :password_digest, null: false

      t.timestamps
    end

    add_index :administrators, :email, unique: true
  end
end
