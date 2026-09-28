require "rails_helper"

RSpec.describe "Admin administrators", type: :request do
  let(:password) { "password123" }
  let!(:administrator) { create(:administrator, first_name: "Pat", password: password) }

  def basic_auth(email, pwd)
    {
      "HTTP_AUTHORIZATION" =>
        ActionController::HttpAuthentication::Basic.encode_credentials(email, pwd)
    }
  end

  it "lists administrators" do
    get admin_administrators_path, headers: basic_auth(administrator.email, password)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(administrator.email)
    expect(response.body).to include("Pat")
  end

  it "creates an administrator" do
    expect {
      post admin_administrators_path,
        params: {
          administrator: {
            first_name: "Jamie",
            last_name: "Ops",
            email: "jamie.ops@dinehub.local",
            password: "password123",
            password_confirmation: "password123"
          }
        },
        headers: basic_auth(administrator.email, password)
    }.to change(Administrator, :count).by(1)

    created = Administrator.find_by!(email: "jamie.ops@dinehub.local")
    expect(response).to redirect_to(admin_administrator_path(created))
  end
end
