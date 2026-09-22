class RestoreCategoryTypeToMenus < ActiveRecord::Migration[8.1]
  CATEGORY_TYPES = { "Specials" => 1, "Drinks" => 2 }.freeze

  def up
    add_column :menus, :category_type, :integer, null: false, default: 0 unless column_exists?(:menus, :category_type)
    remove_index :menus, column: :name if index_exists?(:menus, :name)

    CATEGORY_TYPES.each do |name, category_type|
      execute <<~SQL.squish
        UPDATE menus SET category_type = #{category_type} WHERE name = #{connection.quote(name)}
      SQL
    end
  end

  def down
    remove_column :menus, :category_type, :integer
    add_index :menus, :name, unique: true
  end
end
