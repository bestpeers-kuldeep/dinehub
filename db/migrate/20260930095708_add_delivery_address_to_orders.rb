class AddDeliveryAddressToOrders < ActiveRecord::Migration[8.1]
  def change
    add_reference :orders, :delivery_address, foreign_key: true
    add_reference :orders, :cart, foreign_key: true
  end
end
