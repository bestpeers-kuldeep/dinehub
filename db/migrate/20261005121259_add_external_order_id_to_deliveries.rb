class AddExternalOrderIdToDeliveries < ActiveRecord::Migration[8.1]
  def change
    add_column :deliveries, :external_order_id, :string
  end
end
