module Api
  module V1
    module Admin
      class OrdersController < BaseController
        requires_permission "orders.read"

        def index
          orders = Order.includes(:order_items, :payment, :user).order(created_at: :desc)
          orders = orders.where(user_id: params[:user_id]) if params[:user_id].present?
          orders = orders.where(status: params[:status]) if params[:status].present?
          render json: orders.map { |order| order_json(order) }
        rescue ArgumentError => e
          render json: { error: e.message }, status: :bad_request
        end

        def show
          render json: order_json(Order.find(params[:id]))
        end

        private

        def order_json(order)
          order.as_json(
            include: {
              order_items: { only: %i[id menu_item_id name quantity unit_price total_price] },
              payment: { only: %i[id amount currency gateway status gateway_order_id gateway_payment_id] },
              user: { only: %i[id first_name last_name email phone role] }
            }
          )
        end
      end
    end
  end
end
