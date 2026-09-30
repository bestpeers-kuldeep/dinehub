module Orders
  # Named Errors so this file (orders/errors.rb) matches the constant Zeitwerk
  # expects when CI eager-loads the app.
  module Errors
    class Base < StandardError; end

    # Checkout was asked to snapshot a cart that has no items.
    class CartEmpty < Base; end

    # The cart already has an open order, so its contents are frozen until that
    # order is paid or cancelled.
    class CartNotEditable < Base; end
  end
end
