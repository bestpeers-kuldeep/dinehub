require "rails_helper"

RSpec.describe "Swagger documentation", type: :request do
  it "serves the Swagger UI" do
    get "/api-docs"

    expect(response.status).to be_in([ 200, 301, 302 ])
  end

  it "serves the generated OpenAPI document" do
    get "/api-docs/v1/swagger.yaml"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(
      "/api/v1/menus",
      "/api/v1/reservations",
      "/api/v1/careers",
      "/api/v1/auth/register"
    )
  end
end
