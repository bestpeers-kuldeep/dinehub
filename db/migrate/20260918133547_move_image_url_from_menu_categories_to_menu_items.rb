class MoveImageUrlFromMenuCategoriesToMenuItems < ActiveRecord::Migration[8.1]
  def up
    add_column :menu_items, :image_url, :string

    execute <<~SQL
      UPDATE menu_items
      SET image_url = menu_categories.image_url
      FROM menu_categories
      WHERE menu_items.menu_category_id = menu_categories.id
        AND menu_categories.image_url IS NOT NULL
    SQL

    remove_column :menu_categories, :image_url
  end

  def down
    add_column :menu_categories, :image_url, :string

    execute <<~SQL
      UPDATE menu_categories
      SET image_url = submenu.image_url
      FROM (
        SELECT DISTINCT ON (menu_category_id) menu_category_id, image_url
        FROM menu_items
        WHERE image_url IS NOT NULL
        ORDER BY menu_category_id, id
      ) AS submenu
      WHERE menu_categories.id = submenu.menu_category_id
    SQL

    remove_column :menu_items, :image_url
  end
end
