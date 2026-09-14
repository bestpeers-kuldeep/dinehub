module Api
  module V1
    class MenusController < BaseController
      def index
        menus = Menu.all
        render json: menus
      end

      def show
        menu = Menu.find(params[:id])
        render json: menu
      end
    end
  end
end
