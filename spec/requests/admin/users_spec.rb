require "rails_helper"

RSpec.describe "Admin users", type: :request do
  let(:password) { "password123" }
  let!(:administrator) { create(:administrator, password: password) }
  let!(:user) { create(:user, first_name: "Alex", last_name: "Guest") }

  def basic_auth(email, pwd)
    {
      "HTTP_AUTHORIZATION" =>
        ActionController::HttpAuthentication::Basic.encode_credentials(email, pwd)
    }
  end

  it "lists users for an authenticated administrator" do
    get admin_users_path, headers: basic_auth(administrator.email, password)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(user.email)
    expect(response.body).to include("Alex")
  end

  it "creates a user" do
    expect {
      post admin_users_path,
        params: {
          user: {
            first_name: "Sam",
            last_name: "Host",
            email: "sam.host@example.com",
            phone: "555-0199",
            password: "password123",
            password_confirmation: "password123"
          }
        },
        headers: basic_auth(administrator.email, password)
    }.to change(User, :count).by(1)

    expect(response).to redirect_to(admin_user_path(User.find_by!(email: "sam.host@example.com")))
  end
end
