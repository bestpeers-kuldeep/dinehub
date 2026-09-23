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

          expect(payload["token"]).to be_nil
          expect(payload.dig("user", "id")).to eq(user.id)
          expect(response.cookies["jwt"]).to be_present
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

  path "/api/v1/auth/logout" do
    delete "Log out" do
      tags "Auth"

      response "204", "logged out" do
        let!(:user) { create(:user) }

        before do
          cookies[:jwt] = JsonWebToken.encode({ user_id: user.id })
        end

        run_test! do
          expect(response.cookies["jwt"]).to be_blank
        end
      end
    end
  end

  path "/api/v1/auth/me" do
    get "Get the current user" do
      tags "Auth"
      produces "application/json"
      security [{ BearerAuth: [] }, { CookieAuth: [] }]
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

  path "/api/v1/auth/forgot_password" do
    post "Request a password reset" do
      tags "Auth"
      consumes "application/json"
      produces "application/json"
      parameter name: :payload, in: :body, schema: { "$ref" => "#/components/schemas/ForgotPasswordRequest" }

      response "200", "reset instructions sent" do
        let!(:user) { create(:user) }
        let(:payload) { { email: user.email } }

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body["message"]).to eq("Password reset instructions sent to email")
          expect(user.reload.reset_password_token).to be_present
          expect(user.reset_password_sent_at).to be_present
        end
      end

      response "404", "email not found" do
        let(:payload) { { email: "missing@example.com" } }

        run_test! do |response|
          expect(JSON.parse(response.body)["error"]).to eq("Email not found")
        end
      end

      response "422", "email is missing" do
        let(:payload) { { email: "" } }

        run_test! do |response|
          expect(JSON.parse(response.body).fetch("errors")).to include("Email can't be blank")
        end
      end
    end
  end

  path "/api/v1/auth/reset_password" do
    post "Reset password with a token" do
      tags "Auth"
      consumes "application/json"
      produces "application/json"
      parameter name: :payload, in: :body, schema: { "$ref" => "#/components/schemas/ResetPasswordRequest" }

      response "200", "password updated" do
        let!(:user) { create(:user, password: "password123") }
        let(:raw_token) { user.send_reset_password_instructions }
        let(:payload) { { token: raw_token, password: "newpass123", password_confirmation: "newpass123" } }

        run_test! do |response|
          expect(JSON.parse(response.body)["message"]).to eq("Password has been reset")
          user.reload
          expect(user.authenticate("newpass123")).to be_truthy
          expect(user.reset_password_token).to be_nil
          expect(user.reset_password_sent_at).to be_nil
        end
      end

      response "422", "token is invalid or expired" do
        let(:payload) { { token: "not-a-real-token", password: "newpass123" } }

        run_test! do |response|
          expect(JSON.parse(response.body)["error"]).to eq("Reset token is invalid or expired")
        end
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

  it "authenticates the current user from the jwt cookie" do
    user = create(:user)
    cookies[:jwt] = JsonWebToken.encode({ user_id: user.id })

    get "/api/v1/auth/me"

    expect(response).to have_http_status(:ok)
    expect(json_body["email"]).to eq(user.email)
  end

  it "accepts a nested forgot-password payload and enqueues the email" do
    user = create(:user)

    expect {
      post "/api/v1/auth/forgot_password", params: { user: { email: user.email } }, as: :json
    }.to have_enqueued_mail(UserMailer, :reset_password_instructions)

    expect(response).to have_http_status(:ok)
  end

  it "rejects a password confirmation mismatch" do
    user = create(:user)
    raw_token = user.send_reset_password_instructions

    post "/api/v1/auth/reset_password",
      params: { token: raw_token, password: "newpass123", password_confirmation: "otherpass" },
      as: :json

    expect(response).to have_http_status(:unprocessable_entity)
    expect(json_body.fetch("errors")).to include("Password confirmation doesn't match Password")
    expect(user.reload.authenticate("password123")).to be_truthy
  end
end
