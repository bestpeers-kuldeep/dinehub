require "rails_helper"

RSpec.describe "Admin menu items API", type: :request do
  let(:headers) { auth_headers_for(create(:user, :admin)) }

  it "includes the menu category name on the list" do
    category = create(:menu_category, name: "Starters")
    item = create(:menu_item, menu_category: category, name: "Soup")

    get "/api/v1/admin/menu_items", headers: headers

    expect(response).to have_http_status(:ok)
    listed = json_body.fetch("data").find { |row| row["id"] == item.id }
    expect(listed).to include(
      "name" => "Soup",
      "menu_category_id" => category.id,
      "menu_category_name" => "Starters"
    )
  end
end
