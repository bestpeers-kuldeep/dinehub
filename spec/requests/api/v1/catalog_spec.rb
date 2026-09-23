require "swagger_helper"

RSpec.describe "Public catalog API", type: :request do
  path "/api/v1/menus" do
    get "List menus" do
      tags "Menus"
      produces "application/json"

      response "200", "menus returned" do
        before { create(:menu) }
        run_test!
      end
    end
  end

  path "/api/v1/menus/{id}" do
    get "Get a menu" do
      tags "Menus"
      produces "application/json"
      parameter name: :id, in: :path, type: :integer

      response "200", "menu returned" do
        let(:id) { create(:menu).id }
        run_test!
      end

      response "404", "menu not found" do
        let(:id) { 0 }
        run_test!
      end
    end
  end

  path "/api/v1/menu_categories" do
    get "List menu categories" do
      tags "Menu categories"
      produces "application/json"
      parameter name: :menu_id, in: :query, type: :integer, required: false
      parameter name: :drink_type, in: :query,
        schema: { "$ref" => "#/components/schemas/DrinkType" }, required: false

      response "200", "categories returned" do
        let(:menu_id) { nil }
        let(:drink_type) { nil }
        before { create(:menu_category) }
        run_test!
      end
    end
  end

  path "/api/v1/menu_categories/{id}" do
    get "Get a menu category" do
      tags "Menu categories"
      produces "application/json"
      parameter name: :id, in: :path, type: :integer

      response "200", "category returned" do
        let(:id) { create(:menu_category).id }
        run_test!
      end

      response "404", "category not found" do
        let(:id) { 0 }
        run_test!
      end
    end
  end

  path "/api/v1/menu_items" do
    get "List menu items" do
      tags "Menu items"
      produces "application/json"
      parameter name: :menu_category_id, in: :query, type: :integer, required: false
      parameter name: :drink_type, in: :query,
        schema: { "$ref" => "#/components/schemas/DrinkType" }, required: false

      response "200", "items returned" do
        let(:menu_category_id) { nil }
        let(:drink_type) { nil }
        before { create(:menu_item) }
        run_test!
      end
    end
  end

  path "/api/v1/menu_items/{id}" do
    get "Get a menu item" do
      tags "Menu items"
      produces "application/json"
      parameter name: :id, in: :path, type: :integer

      response "200", "item returned" do
        let(:id) { create(:menu_item).id }
        run_test!
      end

      response "404", "item not found" do
        let(:id) { 0 }
        run_test!
      end
    end
  end

  path "/api/v1/events" do
    get "List events" do
      tags "Events"
      produces "application/json"

      response "200", "events returned" do
        before { create(:event) }
        run_test!
      end
    end
  end

  path "/api/v1/events/{id}" do
    get "Get an event with its items" do
      tags "Events"
      produces "application/json"
      parameter name: :id, in: :path, type: :integer

      response "200", "event returned" do
        let(:id) { create(:event_item).event_id }
        run_test!
      end

      response "404", "event not found" do
        let(:id) { 0 }
        run_test!
      end
    end
  end

  path "/api/v1/specials" do
    get "List this week's specials" do
      tags "Specials"
      produces "application/json"

      response "200", "specials returned" do
        before do
          menu = create(:menu, category_type: :specials)
          category = create(:menu_category, menu: menu)
          create(:menu_item, menu_category: category, start_at: Date.current, end_at: 1.day.from_now)
        end

        run_test!
      end
    end
  end

  it "includes image_url for a menu item with an attached image" do
    item = create(:menu_item)
    item.image.attach(
      io: StringIO.new("fake-image"),
      filename: "bruschetta.jpg",
      content_type: "image/jpeg"
    )

    get "/api/v1/menu_items"

    payload = json_body.find { |row| row["id"] == item.id }
    expect(response).to have_http_status(:ok)
    expect(payload["image_url"]).to eq(item.reload.image_url)
  end
end
