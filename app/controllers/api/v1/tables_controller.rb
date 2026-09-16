module Api
  module V1
    class TablesController < BaseController
      def index
        tables = Table.all
        tables = tables.where(location: params[:location]) if params[:location].present?
        tables = tables.where(capacity: params[:capacity]) if params[:capacity].present?


        render json: tables
      rescue StandardError => e
        render json: { error: e.message }, status: :internal_server_error
      end

      def show
        table = Table.find(params[:id])
        render json: table
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Table not found" }, status: :not_found
      rescue StandardError => e
        render json: { error: e.message }, status: :internal_server_error
      end
    end
  end
end
