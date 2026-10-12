class RemoveCategoryTypeToMenus < ActiveRecord::Migration[8.1]
  # Previous enum: our_menu: 0 (column default), specials: 1, drinks: 2.
  CATEGORY_TYPES = { "Specials" => 1, "Drinks" => 2 }.freeze

  def up
    remove_column :menus, :category_type, :integer
  end

  def down
    add_column :menus, :category_type, :integer, null: false, default: 0

    CATEGORY_TYPES.each do |name, category_type|
      execute <<~SQL.squish
        UPDATE menus SET category_type = #{category_type} WHERE name = #{connection.quote(name)}
      SQL
    end
  end
end
