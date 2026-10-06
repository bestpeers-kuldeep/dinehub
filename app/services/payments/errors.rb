module Payments
  # Typed errors so controllers can map failures to precise HTTP statuses
  # instead of rescuing StandardError and leaking internal messages.
  module Errors
    class Base < StandardError; end

    # Webhook signature/timestamp missing or does not match -> 401
    class Signature < Base; end

    # Webhook body is not JSON / missing required fields -> 400
    class InvalidPayload < Base; end

    # Upstream gateway (Cashfree) returned an error or was unreachable -> 502
    class Gateway < Base; end

    # A Cashfree session is already open for this cart -> 422
    class CheckoutInProgress < Base; end
  end
end
