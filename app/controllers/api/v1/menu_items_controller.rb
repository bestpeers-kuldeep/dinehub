module Api
  module V1
    class MenuItemsController < BaseController
      def index
        menu_items = MenuItem.all
        menu_items = menu_items.where(menu_category_id: params[:menu_category_id]) if params[:menu_category_id].present?
        menu_items = menu_items.for_drink_type(params[:drink_type]) if params[:drink_type].present?
        render json: menu_items
      end

      def show
        menu_item = MenuItem.find(params[:id])
        render json: menu_item
      end
    end
  end
end
