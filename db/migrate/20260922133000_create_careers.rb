class CreateCareers < ActiveRecord::Migration[8.1]
  def change
    create_table :careers do |t|
      t.string :full_name, null: false
      t.string :email, null: false
      t.string :phone, null: false
      t.boolean :opt_in, default: false, null: false
      t.text :experience, null: false
      t.text :cover_letter
      t.string :resume_link

      t.timestamps
    end
  end
end
