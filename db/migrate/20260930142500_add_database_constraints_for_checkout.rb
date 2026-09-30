# Database-level enforcement of the invariants the checkout/payment/delivery
# code assumes. Model validations remain as the friendly first line; these
# constraints guarantee them under races, update_all, raw SQL and console edits.
class AddDatabaseConstraintsForCheckout < ActiveRecord::Migration[8.1]
  def change
    # --- orders ------------------------------------------------------------
    # Order belongs_to :cart is required at the model level; make the DB agree.
    # NOTE: fails if legacy orders exist with cart_id IS NULL. Those rows are
    # already un-updatable through Active Record (validation fails), so
    # backfill or remove them before migrating.
    change_column_null :orders, :cart_id, false

    add_check_constraint :orders, "subtotal >= 0", name: "orders_subtotal_non_negative"
    add_check_constraint :orders, "tax >= 0", name: "orders_tax_non_negative"
    add_check_constraint :orders, "total >= 0", name: "orders_total_non_negative"

    # --- payments ----------------------------------------------------------
    # Order has_one :payment. Without a unique index two concurrent checkout
    # requests could each insert a payment for the same order.
    remove_index :payments, :order_id
    add_index :payments, :order_id, unique: true

    add_check_constraint :payments, "amount > 0", name: "payments_amount_positive"

    # --- carts -------------------------------------------------------------
    # Controllers use `carts.active.first || carts.create`; guarantee at most
    # one live cart per user so that lookup is deterministic.
    add_index :carts, :user_id,
              unique: true,
              where: "status = 0 AND deleted_at IS NULL",
              name: "index_carts_on_user_id_one_active"

    # --- delivery_addresses ------------------------------------------------
    change_column_null :delivery_addresses, :address_line, false
    change_column_null :delivery_addresses, :city, false
    change_column_null :delivery_addresses, :state, false
    change_column_null :delivery_addresses, :postal_code, false
    change_column_null :delivery_addresses, :is_default, false, false

    add_check_constraint :delivery_addresses,
                         "latitude IS NULL OR (latitude >= -90 AND latitude <= 90)",
                         name: "delivery_addresses_latitude_range"
    add_check_constraint :delivery_addresses,
                         "longitude IS NULL OR (longitude >= -180 AND longitude <= 180)",
                         name: "delivery_addresses_longitude_range"

    # At most one default address per user.
    add_index :delivery_addresses, :user_id,
              unique: true,
              where: "is_default",
              name: "index_delivery_addresses_one_default_per_user"

    # --- deliveries --------------------------------------------------------
    change_column_default :deliveries, :status, from: nil, to: 0
    change_column_null :deliveries, :status, false, 0

    # Order has_one :delivery.
    remove_index :deliveries, :order_id
    add_index :deliveries, :order_id, unique: true

    # --- delivery_events ---------------------------------------------------
    change_column_null :delivery_events, :event_type, false
    change_column_default :delivery_events, :payload, from: nil, to: {}

    # Provider webhooks are retried; store each external event once per delivery.
    add_index :delivery_events, [ :delivery_id, :external_event_id ],
              unique: true,
              where: "external_event_id IS NOT NULL",
              name: "index_delivery_events_on_delivery_and_external_event"
  end
end
