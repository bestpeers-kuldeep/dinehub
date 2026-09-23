require "swagger_helper"

RSpec.describe "Auth API", type: :request do
  let(:registration_attributes) { attributes_for(:user) }

  path "/api/v1/auth/register" do
    post "Register a user" do
      tags "Auth"
      consumes "application/json"
      produces "application/json"
      parameter name: :credentials, in: :body, schema: { "$ref" => "#/components/schemas/RegisterRequest" }

      response "201", "user registered" do
        let(:credentials) { registration_attributes }

        run_test! do |response|
          payload = JSON.parse(response.body)

          expect(payload["token"]).to be_present
          expect(payload.dig("user", "first_name")).to eq(registration_attributes[:first_name])
          expect(payload.dig("user", "last_name")).to eq(registration_attributes[:last_name])
          expect(payload.dig("user", "full_name")).to eq(
            "#{registration_attributes[:first_name]} #{registration_attributes[:last_name]}"
          )
          expect(payload.dig("user", "email")).to eq(registration_attributes[:email])
          expect(payload.dig("user", "phone")).to eq(registration_attributes[:phone])
          expect(payload.dig("user", "password")).to be_nil
          expect(payload.dig("user", "password_digest")).to be_nil
        end
      end

      response "422", "validation failed" do
        let(:credentials) { { email: registration_attributes[:email] } }

        run_test! do |response|
          errors = JSON.parse(response.body).fetch("errors")

          expect(errors).to include(
            "First name can't be blank",
            "Last name can't be blank",
            "Phone can't be blank",
            "Password can't be blank"
          )
        end
      end
    end
  end

  path "/api/v1/auth/login" do
    post "Log in" do
      tags "Auth"
      consumes "application/json"
      produces "application/json"
      parameter name: :credentials, in: :body, schema: { "$ref" => "#/components/schemas/LoginRequest" }

      response "200", "authenticated" do
        let!(:user) { create(:user) }
        let(:credentials) { { email: user.email, password: attributes_for(:user)[:password] } }

        run_test! do |response|
          payload = JSON.parse(response.body)

          expect(payload["token"]).to be_present
          expect(payload.dig("user", "id")).to eq(user.id)
        end
      end

      response "401", "invalid credentials" do
        let!(:user) { create(:user) }
        let(:credentials) { { email: user.email, password: "wrong-password" } }

        run_test! do |response|
          expect(JSON.parse(response.body)["error"]).to eq("Invalid email or password")
        end
      end
    end
  end

  path "/api/v1/auth/me" do
    get "Get the current user" do
      tags "Auth"
      produces "application/json"
      security [BearerAuth: []]
      parameter name: :Authorization, in: :header, type: :string, required: false

      response "200", "current user" do
        let!(:user) { create(:user) }
        let(:Authorization) { "Bearer #{JsonWebToken.encode({ user_id: user.id })}" }

        run_test! do |response|
          payload = JSON.parse(response.body)

          expect(payload["email"]).to eq(user.email)
          expect(payload["first_name"]).to eq(user.first_name)
        end
      end

      response "401", "unauthorized" do
        let(:Authorization) { nil }
        run_test!
      end
    end
  end

  it "registers a user nested under user" do
    post "/api/v1/auth/register", params: { user: registration_attributes }, as: :json

    expect(response).to have_http_status(:created)
    expect(json_body.dig("user", "first_name")).to eq(registration_attributes[:first_name])
  end

  it "rejects the current-user endpoint with an invalid token" do
    get "/api/v1/auth/me", headers: { "Authorization" => "Bearer not-a-token" }

    expect(response).to have_http_status(:unauthorized)
  end
end
