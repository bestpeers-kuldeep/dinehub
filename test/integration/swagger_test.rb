require "test_helper"

class SwaggerTest < ActionDispatch::IntegrationTest
  test "serves swagger ui" do
    get "/api-docs"

    assert_includes [ 200, 301, 302 ], response.status
  end

  test "serves the openapi document" do
    get "/api-docs/v1/swagger.yaml"

    assert_response :success
    assert_match %r{/api/v1/menus}, response.body
    assert_match %r{/api/v1/reservations}, response.body
    assert_match %r{/api/v1/careers}, response.body
  end
end
