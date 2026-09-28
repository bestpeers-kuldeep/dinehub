require "rails_helper"

RSpec.describe "Admin panel authentication", type: :request do
  let(:password) { "password123" }
  let!(:administrator) { create(:administrator, password: password) }
  let!(:user) { create(:user, password: password) }

  def basic_auth(email, pwd)
    {
      "HTTP_AUTHORIZATION" =>
        ActionController::HttpAuthentication::Basic.encode_credentials(email, pwd)
    }
  end

  it "requires authentication" do
    get admin_root_path

    expect(response).to have_http_status(:unauthorized)
  end

  it "rejects a regular user" do
    get admin_root_path, headers: basic_auth(user.email, password)

    expect(response).to have_http_status(:unauthorized)
  end

  it "allows an administrator" do
    get admin_root_path, headers: basic_auth(administrator.email, password)

    expect(response).to have_http_status(:ok)
  end
end
