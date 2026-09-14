module Api
  module V1
    class MenuCategoriesController < BaseController
      def index
        menu_categories = MenuCategory.all
        menu_categories = menu_categories.where(menu_id: params[:menu_id]) if params[:menu_id].present?
        menu_categories = menu_categories.where(drink_type: params[:drink_type]) if params[:drink_type].present?
        render json: menu_categories
      end

      def show
        menu_category = MenuCategory.find(params[:id])
        render json: menu_category
      end
    end
  end
end
