require "rails_helper"

RSpec.describe "CORS", type: :request do
  let(:allowed_origin) { "https://allowed.test" }
  let(:blocked_origin) { "https://evil.example" }

  it "allows requests from a configured origin" do
    get "/api/v1/menus", headers: { "Origin" => allowed_origin }

    expect(response).to have_http_status(:ok)
    expect(response.headers["Access-Control-Allow-Origin"]).to eq(allowed_origin)
  end

  it "does not allow requests from an unconfigured origin" do
    get "/api/v1/menus", headers: { "Origin" => blocked_origin }

    expect(response).to have_http_status(:ok)
    expect(response.headers["Access-Control-Allow-Origin"]).to be_nil
  end

  it "answers preflight for a configured origin" do
    process :options, "/api/v1/menus", headers: {
      "Origin" => allowed_origin,
      "Access-Control-Request-Method" => "GET"
    }

    expect(response.status).to be_in([ 200, 204 ])
    expect(response.headers["Access-Control-Allow-Origin"]).to eq(allowed_origin)
    expect(response.headers["Access-Control-Allow-Methods"]).to match(/GET/i)
  end

  it "does not answer preflight for an unconfigured origin" do
    process :options, "/api/v1/menus", headers: {
      "Origin" => blocked_origin,
      "Access-Control-Request-Method" => "GET"
    }

    expect(response.headers["Access-Control-Allow-Origin"]).to be_nil
  end
end
