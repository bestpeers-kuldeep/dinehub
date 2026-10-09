module Admin
  class DashboardSummary
    def initialize(from:, to:)
      @from = from
      @to = to
    end

    def call
      today = Date.current

      {
        today: period(today, today),
        range: period(@from, @to)
      }
    end

    private

    def period(from, to)
      window = from.in_time_zone.beginning_of_day..to.in_time_zone.end_of_day
      orders_by_status = orders_by_status(window)

      {
        from: from.iso8601,
        to: to.iso8601,
        orders_by_status: orders_by_status,
        orders_total: orders_by_status.values.sum,
        revenue: format("%.2f", revenue(window)),
        reservations: reservations(from, to),
        active_users: active_users(window)
      }
    end

    def orders_by_status(window)
      grouped = Order.where(created_at: window).group(:status).count

      Order.statuses.each_with_object({}) do |(name, value), counts|
        counts[name] = grouped[name] || grouped[value] || 0
      end
    end

    def revenue(window)
      Payment.successful.where(created_at: window).sum(:amount)
    end

    def reservations(from, to)
      Reservation.where(active: true, reservation_date: from..to).count
    end

    def active_users(window)
      User.customer.where(id: Order.where(created_at: window).select(:user_id)).count
    end
  end
end
