class Payment < ApplicationRecord
  belongs_to :cart
  belongs_to :order, optional: true
  belongs_to :delivery_address, optional: true

  enum :status, {
    pending: 0,
    processing: 1,
    successful: 2,
    failed: 3,
    cancelled: 4
  }

  # Checkout rows have no order until the payment webhook creates one.
  scope :open_checkout, -> { where(order_id: nil, status: [ :pending, :processing ]) }

  validates :gateway, presence: true
  validates :amount, numericality: { greater_than: 0 }
  validates :currency, presence: true
  # One payment row per order (Order has_one :payment); unique index on order_id.
  validates :order_id, uniqueness: true, allow_nil: true
  validates :gateway_order_id, uniqueness: { scope: :gateway }, allow_nil: true

  def terminal?
    successful? || failed? || cancelled?
  end

  def self.total_for(items)
    items.sum { |item| item.quantity * item.unit_price.to_d }
  end

  def self.checkout_snapshot(items, total)
    {
      "subtotal" => total.to_s("F"),
      "tax" => "0.0",
      "total" => total.to_s("F"),
      "items" => items.map { |item|
        {
          "menu_item_id" => item.menu_item_id,
          "name" => item.menu_item.name,
          "quantity" => item.quantity,
          "unit_price" => item.unit_price.to_s("F")
        }
      }
    }
  end

  # A Cashfree session is priced at the cart total from when checkout started.
  # The session can be reused only while the cart still matches that total.
  def checkout_current?(items, total)
    return false unless amount.to_d == total.to_d

    stored_items = metadata.dig("checkout", "items")
    return true if stored_items.blank?

    item_key(stored_items) == item_key(items)
  end

  # Drops an open checkout whose amount no longer matches the cart. The row
  # stays so a late webhook for the old session can still be applied.
  def abandon_for_cart_change!
    update!(
      status: :cancelled,
      metadata: metadata.merge("abandoned_reason" => "cart_changed")
    )
  end

  private

  def item_key(items)
    items.map { |item|
      [
        item_value(item, :menu_item_id, "menu_item_id").to_i,
        item_value(item, :quantity, "quantity").to_i,
        BigDecimal(item_value(item, :unit_price, "unit_price").to_s)
      ]
    }.sort
  end

  def item_value(item, method_name, key)
    item.respond_to?(method_name) ? item.public_send(method_name) : item[key]
  end
end
