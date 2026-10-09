module Paginatable
  extend ActiveSupport::Concern

  DEFAULT_PER_PAGE = 25
  MAX_PER_PAGE = 100

  private

  def render_collection(scope)
    page = pagination_params[:page]
    per_page = pagination_params[:per_page]
    total_count = pagination_count(scope)
    records = scope.offset((page - 1) * per_page).limit(per_page)
    data = block_given? ? yield(records) : records

    render json: {
      data: data,
      pagination: {
        page: page,
        per_page: per_page,
        total_count: total_count,
        total_pages: total_count.zero? ? 0 : (total_count.to_f / per_page).ceil
      }
    }
  end

  def pagination_count(scope)
    count = scope.except(:includes, :preload, :eager_load, :order, :limit, :offset).count
    count.is_a?(Hash) ? count.values.sum : count
  end
end
