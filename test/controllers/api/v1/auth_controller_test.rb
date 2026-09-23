require "test_helper"

class Api::V1::AuthControllerTest < ActionDispatch::IntegrationTest
  setup do
    @register_params = {
      first_name: "Sam",
      last_name: "Diner",
      email: "sam@example.com",
      phone: "555-0200",
      password: "password123"
    }
  end

  test "registers a user and returns a jwt" do
    assert_difference -> { User.count }, 1 do
      post "/api/v1/auth/register", params: @register_params, as: :json
    end

    assert_response :created
    body = JSON.parse(response.body)
    assert body["token"].present?
    assert_equal "Sam", body.dig("user", "first_name")
    assert_equal "Diner", body.dig("user", "last_name")
    assert_equal "Sam Diner", body.dig("user", "full_name")
    assert_equal "sam@example.com", body.dig("user", "email")
    assert_equal "555-0200", body.dig("user", "phone")
    assert_nil body.dig("user", "password")
    assert_nil body.dig("user", "password_digest")
  end

  test "registers a user nested under user" do
    post "/api/v1/auth/register", params: { user: @register_params }, as: :json

    assert_response :created
    assert_equal "Sam", JSON.parse(response.body).dig("user", "first_name")
  end

  test "rejects registration without required fields" do
    post "/api/v1/auth/register", params: { email: "sam@example.com" }, as: :json

    assert_response :unprocessable_entity
    errors = JSON.parse(response.body)["errors"]
    assert_includes errors, "First name can't be blank"
    assert_includes errors, "Last name can't be blank"
    assert_includes errors, "Phone can't be blank"
    assert_includes errors, "Password can't be blank"
  end

  test "logs in with email and password" do
    post "/api/v1/auth/login", params: {
      email: users(:alex).email,
      password: "password123"
    }, as: :json

    assert_response :success
    body = JSON.parse(response.body)
    assert body["token"].present?
    assert_equal users(:alex).id, body.dig("user", "id")
  end

  test "rejects login with invalid credentials" do
    post "/api/v1/auth/login", params: {
      email: users(:alex).email,
      password: "wrong-password"
    }, as: :json

    assert_response :unauthorized
    assert_equal "Invalid email or password", JSON.parse(response.body)["error"]
  end

  test "returns the current user for a valid token" do
    post "/api/v1/auth/login", params: {
      email: users(:alex).email,
      password: "password123"
    }, as: :json
    token = JSON.parse(response.body)["token"]

    get "/api/v1/auth/me", headers: { "Authorization" => "Bearer #{token}" }

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal users(:alex).email, body["email"]
    assert_equal "Alex", body["first_name"]
  end

  test "rejects me without a token" do
    get "/api/v1/auth/me"

    assert_response :unauthorized
    assert_equal "Unauthorized", JSON.parse(response.body)["error"]
  end

  test "rejects me with an invalid token" do
    get "/api/v1/auth/me", headers: { "Authorization" => "Bearer not-a-token" }

    assert_response :unauthorized
  end
end
