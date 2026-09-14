# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_09_14_101200) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "menu_categories", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "menu_id", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["menu_id"], name: "index_menu_categories_on_menu_id"
  end

  create_table "menu_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.datetime "end_at"
    t.bigint "menu_category_id", null: false
    t.string "name", null: false
    t.decimal "price", precision: 10, scale: 2, null: false
    t.datetime "start_at"
    t.datetime "updated_at", null: false
    t.index ["menu_category_id"], name: "index_menu_items_on_menu_category_id"
    t.index ["name"], name: "index_menu_items_on_name"
  end

  create_table "menus", force: :cascade do |t|
    t.integer "category_type", default: 0, null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "menu_categories", "menus"
  add_foreign_key "menu_items", "menu_categories"
end
