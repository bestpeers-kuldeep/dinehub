module Orders
  # Kitchen-style progress. Payment creates the order as confirmed; the
  # client may only move it forward, or cancel it before it is finished.
  class UpdateStatus
    TRANSITIONS = {
      "pending" => %w[confirmed preparing cancelled],
      "confirmed" => %w[preparing cancelled],
      "preparing" => %w[ready cancelled],
      "ready" => %w[completed cancelled]
    }.freeze

    def initialize(order, status)
      @order = order
      @status = status.to_s
    end

    def call
      unless Order.statuses.key?(@status)
        raise Errors::InvalidStatus, "Unknown order status"
      end

      allowed = TRANSITIONS.fetch(@order.status, [])
      unless allowed.include?(@status)
        raise Errors::InvalidStatus, "Cannot change an order from #{@order.status} to #{@status}"
      end

      @order.update!(status: @status)
      @order
    end
  end
end
