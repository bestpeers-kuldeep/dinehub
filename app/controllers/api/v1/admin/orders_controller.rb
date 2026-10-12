module Api
  module V1
    module Admin
      class OrdersController < BaseController
        requires_permission "orders.read"

        def index
          orders = Order.includes(:order_items, :payment, :user, :delivery).order(created_at: :desc)
          orders = orders.where(user_id: params[:user_id]) if params[:user_id].present?
          orders = orders.where(status: params[:status]) if params[:status].present?
          render_collection(orders) { |records| records.map { |order| order_json(order) } }
        rescue ArgumentError => e
          render json: { error: e.message }, status: :bad_request
        end

        def show
          render json: order_json(Order.includes(:delivery).find(params[:id]))
        end

        def update
          order = Order.includes(:delivery).find(params[:id])
          ::Orders::UpdateStatus.new(order, params.require(:status)).call
          render json: order_json(order.reload)
        rescue ::Orders::Errors::InvalidStatus, Deliveries::Providers::Borzo::Client::Error, ActionController::ParameterMissing => e
          render json: { error: e.message }, status: :unprocessable_entity
        end

        def tracking
          order = Order.includes(:delivery).find(params[:id])
          result = Deliveries::RefreshTracking.new(order).call
          body = Deliveries::TrackingPayload.for(result.order)
          body[:error] = result.error if result.error.present?
          render json: body, status: result.http_status
        end

        private

        def order_json(order)
          payload = order.as_json(
            include: {
              order_items: { only: %i[id menu_item_id name quantity unit_price total_price] },
              payment: { only: %i[id amount currency gateway status gateway_order_id gateway_payment_id] },
              user: { only: %i[id first_name last_name email phone role] }
            }
          )
          payload["delivery"] = order.delivery&.as_json(
            only: %i[id status provider tracking_url external_order_id rider_name rider_phone]
          )
          payload
        end
      end
    end
  end
end
