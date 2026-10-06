# A checkout payment is created from the cart. The order row is inserted only
# after Cashfree reports success, so payments must be able to exist first.
class AllowCheckoutBeforeOrder < ActiveRecord::Migration[8.1]
  def up
    add_reference :payments, :cart, foreign_key: true
    add_reference :payments, :delivery_address, foreign_key: true

    execute <<~SQL
      UPDATE payments
      SET cart_id = orders.cart_id,
          delivery_address_id = orders.delivery_address_id
      FROM orders
      WHERE payments.order_id = orders.id
        AND payments.cart_id IS NULL
    SQL

    change_column_null :payments, :cart_id, false
    change_column_null :payments, :order_id, true

    # One in-flight checkout per cart. Failed attempts stay, and a successful
    # payment leaves this index once it is attached to an order.
    add_index :payments, :cart_id,
              unique: true,
              where: "order_id IS NULL AND status IN (0, 1)",
              name: "index_payments_one_open_checkout_per_cart"
  end

  def down
    remove_index :payments, name: "index_payments_one_open_checkout_per_cart"
    execute "DELETE FROM payments WHERE order_id IS NULL"
    change_column_null :payments, :order_id, false
    remove_reference :payments, :delivery_address, foreign_key: true
    remove_reference :payments, :cart, foreign_key: true
  end
end
