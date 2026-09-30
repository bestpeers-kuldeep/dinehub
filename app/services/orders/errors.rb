module Orders
  class Error < StandardError; end

  # Checkout was asked to snapshot a cart that has no items.
  class CartEmpty < Error; end

  # The cart already has an open order, so its contents are frozen until that
  # order is paid or cancelled.
  class CartNotEditable < Error; end
end
