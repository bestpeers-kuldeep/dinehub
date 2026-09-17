require "test_helper"

class CorsTest < ActionDispatch::IntegrationTest
  ALLOWED_ORIGIN = "https://allowed.test"
  BLOCKED_ORIGIN = "https://evil.example"

  test "allows requests from a configured origin" do
    get "/api/v1/menus", headers: { "Origin" => ALLOWED_ORIGIN }

    assert_response :success
    assert_equal ALLOWED_ORIGIN, response.headers["Access-Control-Allow-Origin"]
  end

  test "rejects requests from an origin that is not configured" do
    get "/api/v1/menus", headers: { "Origin" => BLOCKED_ORIGIN }

    assert_response :success
    assert_nil response.headers["Access-Control-Allow-Origin"]
  end

  test "answers preflight only for a configured origin" do
    process :options, "/api/v1/menus", headers: {
      "Origin" => ALLOWED_ORIGIN,
      "Access-Control-Request-Method" => "GET"
    }

    assert_includes [ 200, 204 ], response.status
    assert_equal ALLOWED_ORIGIN, response.headers["Access-Control-Allow-Origin"]
    assert_match(/GET/i, response.headers["Access-Control-Allow-Methods"].to_s)
  end

  test "does not answer preflight for an origin that is not configured" do
    process :options, "/api/v1/menus", headers: {
      "Origin" => BLOCKED_ORIGIN,
      "Access-Control-Request-Method" => "GET"
    }

    assert_nil response.headers["Access-Control-Allow-Origin"]
  end
end
