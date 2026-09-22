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

ActiveRecord::Schema[8.1].define(version: 2026_09_22_133000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "careers", force: :cascade do |t|
    t.text "cover_letter"
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.text "experience", null: false
    t.string "full_name", null: false
    t.boolean "opt_in", default: false, null: false
    t.string "phone", null: false
    t.string "resume_link"
    t.datetime "updated_at", null: false
  end

  create_table "event_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.time "end_time"
    t.date "event_date", null: false
    t.bigint "event_id", null: false
    t.string "logo_url"
    t.time "start_time"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["event_date"], name: "index_event_items_on_event_date"
    t.index ["event_id"], name: "index_event_items_on_event_id"
  end

  create_table "events", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
  end

  create_table "menu_categories", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "drink_type"
    t.bigint "menu_id", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["menu_id"], name: "index_menu_categories_on_menu_id"
  end

  create_table "menu_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.datetime "end_at"
    t.string "image_url"
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

  create_table "reservations", force: :cascade do |t|
    t.decimal "budget_per_person", precision: 10, scale: 2
    t.string "company"
    t.datetime "created_at", null: false
    t.text "description"
    t.string "duration"
    t.string "email", null: false
    t.string "full_name"
    t.boolean "marketing_opt_in", default: false, null: false
    t.integer "number_of_people"
    t.string "occasion"
    t.string "phone", null: false
    t.date "reservation_date", null: false
    t.string "source"
    t.text "special_requests"
    t.time "start_time", null: false
    t.bigint "table_id"
    t.string "type", default: "TableReservation", null: false
    t.datetime "updated_at", null: false
    t.index ["table_id", "reservation_date", "start_time"], name: "index_reservations_on_table_date_start", unique: true, where: "(table_id IS NOT NULL)"
    t.index ["table_id", "reservation_date"], name: "index_reservations_on_table_id_and_reservation_date"
    t.index ["table_id"], name: "index_reservations_on_table_id"
    t.index ["type"], name: "index_reservations_on_type"
  end

  create_table "tables", force: :cascade do |t|
    t.integer "capacity", null: false
    t.datetime "created_at", null: false
    t.integer "location", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["location"], name: "index_tables_on_location"
    t.index ["name"], name: "index_tables_on_name", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "event_items", "events"
  add_foreign_key "menu_categories", "menus"
  add_foreign_key "menu_items", "menu_categories"
  add_foreign_key "reservations", "tables"
end
