require "rails_helper"

RSpec.describe "Admin list pagination", type: :request do
  let(:headers) { auth_headers_for(create(:user, :admin)) }

  %w[
    /api/v1/admin/menus
    /api/v1/admin/menu_categories
    /api/v1/admin/menu_items
    /api/v1/admin/customers
    /api/v1/admin/orders
    /api/v1/admin/catering_reservations
    /api/v1/admin/tables
    /api/v1/admin/table_reservations
  ].each do |path|
    it "paginates #{path}" do
      get path, params: { page: 1, per_page: 1 }, headers: headers

      expect(response).to have_http_status(:ok)
      expect(json_body["data"]).to be_an(Array)
      expect(json_body["data"].size).to be <= 1
      expect(json_body["pagination"]).to include("page" => 1, "per_page" => 1)
      expect(json_body["pagination"]).to have_key("total_pages")
      expect(json_body["pagination"]["total_count"]).to be_a(Integer)
    end
  end

  it "defaults to the first page of 25 records when page is omitted" do
    get "/api/v1/admin/menus", headers: headers

    expect(response).to have_http_status(:ok)
    expect(json_body["pagination"]).to include("page" => 1, "per_page" => 25)
  end

  it "accepts a page number and keeps 25 records per page" do
    get "/api/v1/admin/menus", params: { page: 2 }, headers: headers

    expect(response).to have_http_status(:ok)
    expect(json_body["pagination"]).to include("page" => 2, "per_page" => 25)
  end
end
