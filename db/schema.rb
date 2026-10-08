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

ActiveRecord::Schema[8.1].define(version: 2026_10_08_140000) do
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

  create_table "cart_items", force: :cascade do |t|
    t.bigint "cart_id", null: false
    t.datetime "created_at", null: false
    t.bigint "menu_item_id", null: false
    t.integer "quantity", null: false
    t.decimal "unit_price"
    t.datetime "updated_at", null: false
    t.index ["cart_id", "menu_item_id"], name: "index_cart_items_on_cart_id_and_menu_item_id", unique: true
    t.index ["cart_id"], name: "index_cart_items_on_cart_id"
    t.index ["menu_item_id"], name: "index_cart_items_on_menu_item_id"
  end

  create_table "carts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_carts_on_user_id"
    t.index ["user_id"], name: "index_carts_on_user_id_one_active", unique: true, where: "((status = 0) AND (deleted_at IS NULL))"
  end

  create_table "deliveries", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "external_delivery_id"
    t.string "external_order_id"
    t.jsonb "metadata"
    t.bigint "order_id", null: false
    t.string "provider"
    t.decimal "rider_latitude"
    t.decimal "rider_longitude"
    t.string "rider_name"
    t.string "rider_phone"
    t.integer "status", default: 0, null: false
    t.string "tracking_number"
    t.string "tracking_url"
    t.datetime "updated_at", null: false
    t.index ["order_id"], name: "index_deliveries_on_order_id", unique: true
    t.index ["provider", "external_delivery_id"], name: "index_deliveries_on_provider_and_external_delivery_id", unique: true, where: "(external_delivery_id IS NOT NULL)"
  end

  create_table "delivery_addresses", force: :cascade do |t|
    t.text "address_line", null: false
    t.string "city", null: false
    t.datetime "created_at", null: false
    t.boolean "is_default", default: false, null: false
    t.string "landmark"
    t.decimal "latitude"
    t.decimal "longitude"
    t.string "postal_code", null: false
    t.string "state", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_delivery_addresses_on_user_id"
    t.index ["user_id"], name: "index_delivery_addresses_one_default_per_user", unique: true, where: "is_default"
    t.check_constraint "latitude IS NULL OR latitude >= '-90'::integer::numeric AND latitude <= 90::numeric", name: "delivery_addresses_latitude_range"
    t.check_constraint "longitude IS NULL OR longitude >= '-180'::integer::numeric AND longitude <= 180::numeric", name: "delivery_addresses_longitude_range"
  end

  create_table "delivery_events", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "delivery_id", null: false
    t.string "event_type", null: false
    t.string "external_event_id"
    t.jsonb "payload", default: {}
    t.datetime "updated_at", null: false
    t.index ["delivery_id", "external_event_id"], name: "index_delivery_events_on_delivery_and_external_event", unique: true, where: "(external_event_id IS NOT NULL)"
    t.index ["delivery_id"], name: "index_delivery_events_on_delivery_id"
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

  create_table "order_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "menu_item_id", null: false
    t.string "name", null: false
    t.bigint "order_id", null: false
    t.integer "quantity", null: false
    t.decimal "total_price", precision: 10, scale: 2, null: false
    t.decimal "unit_price", precision: 10, scale: 2, null: false
    t.datetime "updated_at", null: false
    t.index ["menu_item_id"], name: "index_order_items_on_menu_item_id"
    t.index ["order_id"], name: "index_order_items_on_order_id"
  end

  create_table "orders", force: :cascade do |t|
    t.bigint "cart_id", null: false
    t.datetime "created_at", null: false
    t.bigint "delivery_address_id"
    t.integer "status", default: 0, null: false
    t.decimal "subtotal", precision: 10, scale: 2, null: false
    t.decimal "tax", precision: 10, scale: 2, default: "0.0", null: false
    t.decimal "total", precision: 10, scale: 2, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["cart_id"], name: "index_orders_on_cart_id"
    t.index ["delivery_address_id"], name: "index_orders_on_delivery_address_id"
    t.index ["user_id"], name: "index_orders_on_user_id"
    t.check_constraint "subtotal >= 0::numeric", name: "orders_subtotal_non_negative"
    t.check_constraint "tax >= 0::numeric", name: "orders_tax_non_negative"
    t.check_constraint "total >= 0::numeric", name: "orders_total_non_negative"
  end

  create_table "payments", force: :cascade do |t|
    t.decimal "amount", precision: 12, scale: 2, null: false
    t.bigint "cart_id", null: false
    t.datetime "created_at", null: false
    t.string "currency", null: false
    t.bigint "delivery_address_id"
    t.string "gateway", null: false
    t.string "gateway_order_id"
    t.string "gateway_payment_id"
    t.jsonb "metadata", default: {}, null: false
    t.bigint "order_id"
    t.string "payment_session_id"
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["cart_id"], name: "index_payments_on_cart_id"
    t.index ["cart_id"], name: "index_payments_one_open_checkout_per_cart", unique: true, where: "((order_id IS NULL) AND (status = ANY (ARRAY[0, 1])))"
    t.index ["delivery_address_id"], name: "index_payments_on_delivery_address_id"
    t.index ["gateway", "gateway_order_id"], name: "index_payments_on_gateway_and_gateway_order_id", unique: true
    t.index ["gateway_order_id"], name: "index_payments_on_gateway_order_id"
    t.index ["order_id"], name: "index_payments_on_order_id", unique: true
    t.check_constraint "amount > 0::numeric", name: "payments_amount_positive"
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

  create_table "users", force: :cascade do |t|
    t.string "additional_phone"
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "password_digest", null: false
    t.string "phone", null: false
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.integer "role", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["phone"], name: "index_users_on_phone", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["role"], name: "index_users_on_role"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "cart_items", "carts"
  add_foreign_key "cart_items", "menu_items"
  add_foreign_key "carts", "users"
  add_foreign_key "deliveries", "orders"
  add_foreign_key "delivery_addresses", "users"
  add_foreign_key "delivery_events", "deliveries"
  add_foreign_key "event_items", "events"
  add_foreign_key "menu_categories", "menus"
  add_foreign_key "menu_items", "menu_categories"
  add_foreign_key "order_items", "menu_items"
  add_foreign_key "order_items", "orders"
  add_foreign_key "orders", "carts"
  add_foreign_key "orders", "delivery_addresses"
  add_foreign_key "orders", "users"
  add_foreign_key "payments", "carts"
  add_foreign_key "payments", "delivery_addresses"
  add_foreign_key "payments", "orders"
  add_foreign_key "reservations", "tables"
end
