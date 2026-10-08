module Api
  module V1
    module Admin
      class MenuItemsController < BaseController
        requires_permission "menu_items.manage"

        ITEM_KEYS = %i[name description price menu_category_id start_at end_at image_url image].freeze

        before_action :set_menu_item, only: %i[show update destroy]

        def index
          items = MenuItem.order(:name)
          items = items.where(menu_category_id: params[:menu_category_id]) if params[:menu_category_id].present?
          render json: items
        end

        def show
          render json: @menu_item
        end

        def create
          item = MenuItem.new(item_attributes)
          item.image.attach(image_file) if image_file.present?
          item.save!
          render json: item, status: :created
        rescue ActiveRecord::RecordInvalid => e
          render_validation_error(e)
        end

        def update
          @menu_item.assign_attributes(item_attributes)
          @menu_item.image.attach(image_file) if image_file.present?
          @menu_item.save!
          render json: @menu_item
        rescue ActiveRecord::RecordInvalid => e
          render_validation_error(e)
        end

        def destroy
          @menu_item.destroy!
          head :no_content
        rescue ActiveRecord::RecordNotDestroyed => e
          render_destroy_error(e)
        end

        private

        def set_menu_item
          @menu_item = MenuItem.find(params[:id])
        end

        def item_attributes
          resource_params(*ITEM_KEYS).except(:image)
        end

        def image_file
          resource_params(*ITEM_KEYS)[:image]
        end
      end
    end
  end
end
