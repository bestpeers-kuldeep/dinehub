module Api
  module V1
    class SpecialsController < BaseController
      # GET /api/v1/specials
      # Week window is fixed: today .. today + 6 days (no date params).
      # Filters specials menu_items by start_at / end_at overlap.
      def index
        start_date = Date.current
        end_date = start_date + 6.days

        payload = Rails.cache.fetch(cache_key(start_date), expires_in: cache_expires_in) do
          build_week_specials(start_date, end_date)
        end

        render json: payload
      end

      private

      def cache_key(start_date)
        "api/v1/specials/week/#{start_date.iso8601}"
      end

      # Cache until end of today so the window rolls overnight.
      def cache_expires_in
        seconds = Time.current.end_of_day - Time.current
        [ seconds, 1.minute ].max
      end

      def build_week_specials(start_date, end_date)
        menu = Menu.specials.first
        menu_items = if menu
          MenuItem
            .joins(:menu_category)
            .where(menu_categories: { menu_id: menu.id })
            .active_between(start_date, end_date)
            .includes(:menu_category)
            .order(:start_at, :name)
        else
          MenuItem.none
        end

        {
          start_date: start_date.iso8601,
          end_date: end_date.iso8601,
          menu: menu && { id: menu.id, name: menu.name, category_type: menu.category_type },
          menu_items: menu_items.map { |item| serialize_item(item) }
        }
      end

      def serialize_item(item)
        {
          id: item.id,
          name: item.name,
          description: item.description,
          price: item.price,
          start_at: item.start_at,
          end_at: item.end_at,
          menu_category_id: item.menu_category_id,
          menu_category_name: item.menu_category.name,
          image_url: item.image_url
        }
      end
    end
  end
end
