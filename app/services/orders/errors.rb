module Orders
  # Named Errors so this file (orders/errors.rb) matches the constant Zeitwerk
  # expects when CI eager-loads the app.
  module Errors
    class Base < StandardError; end

    # Checkout was asked to snapshot a cart that has no items.
    class CartEmpty < Base; end

    # The cart already has an open checkout, so its contents are frozen until
    # that payment succeeds or fails.
    class CartNotEditable < Base; end

    class InvalidStatus < Base; end
  end
end
