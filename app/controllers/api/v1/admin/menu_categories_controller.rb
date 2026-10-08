module Api
  module V1
    module Admin
      class MenuCategoriesController < BaseController
        requires_permission "menu_categories.manage"

        before_action :set_menu_category, only: %i[show update destroy]

        def index
          categories = MenuCategory.order(:name)
          categories = categories.where(menu_id: params[:menu_id]) if params[:menu_id].present?
          render json: categories
        end

        def show
          render json: @menu_category
        end

        def create
          category = MenuCategory.create!(resource_params(:name, :menu_id, :drink_type))
          render json: category, status: :created
        rescue ActiveRecord::RecordInvalid => e
          render_validation_error(e)
        rescue ArgumentError => e
          render json: { errors: [ e.message ] }, status: :unprocessable_entity
        end

        def update
          @menu_category.update!(resource_params(:name, :menu_id, :drink_type))
          render json: @menu_category
        rescue ActiveRecord::RecordInvalid => e
          render_validation_error(e)
        rescue ArgumentError => e
          render json: { errors: [ e.message ] }, status: :unprocessable_entity
        end

        def destroy
          @menu_category.destroy!
          head :no_content
        rescue ActiveRecord::RecordNotDestroyed => e
          render_destroy_error(e)
        end

        private

        def set_menu_category
          @menu_category = MenuCategory.find(params[:id])
        end
      end
    end
  end
end
