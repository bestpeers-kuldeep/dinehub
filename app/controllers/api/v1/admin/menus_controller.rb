module Api
  module V1
    module Admin
      class MenusController < BaseController
        requires_permission "menus.manage"

        before_action :set_menu, only: %i[show update destroy]

        def index
          render json: Menu.order(:name)
        end

        def show
          render json: @menu
        end

        def create
          menu = Menu.create!(resource_params(:name, :category_type))
          render json: menu, status: :created
        rescue ActiveRecord::RecordInvalid => e
          render_validation_error(e)
        rescue ArgumentError => e
          render json: { errors: [ e.message ] }, status: :unprocessable_entity
        end

        def update
          @menu.update!(resource_params(:name, :category_type))
          render json: @menu
        rescue ActiveRecord::RecordInvalid => e
          render_validation_error(e)
        rescue ArgumentError => e
          render json: { errors: [ e.message ] }, status: :unprocessable_entity
        end

        def destroy
          @menu.destroy!
          head :no_content
        rescue ActiveRecord::RecordNotDestroyed => e
          render_destroy_error(e)
        end

        private

        def set_menu
          @menu = Menu.find(params[:id])
        end
      end
    end
  end
end
