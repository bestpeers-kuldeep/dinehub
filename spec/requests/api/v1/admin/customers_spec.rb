require "rails_helper"

RSpec.describe "Admin customers API", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:headers) { auth_headers_for(admin) }

  it "creates, updates, lists, and deletes customer users without promoting them" do
    post "/api/v1/admin/customers",
      params: {
        customer: {
          first_name: "Sam",
          last_name: "Diner",
          email: "sam@example.com",
          phone: "555-2222",
          password: "password123",
          role: "admin"
        }
      },
      headers: headers,
      as: :json

    expect(response).to have_http_status(:created)
    customer_id = json_body.fetch("id")
    expect(json_body["role"]).to eq("customer")
    expect(json_body).not_to have_key("password_digest")

    patch "/api/v1/admin/customers/#{customer_id}",
      params: { first_name: "Samuel", role: "admin" },
      headers: headers,
      as: :json

    expect(response).to have_http_status(:ok)
    expect(json_body["first_name"]).to eq("Samuel")
    expect(User.find(customer_id).role).to eq("customer")

    other_admin = create(:user, :admin)
    get "/api/v1/admin/customers", headers: headers

    ids = json_body.map { |user| user["id"] }
    expect(ids).to include(customer_id)
    expect(ids).not_to include(admin.id, other_admin.id)

    customer = User.find(customer_id)
    create(:order, user: customer)
    delete "/api/v1/admin/customers/#{customer_id}", headers: headers

    expect(response).to have_http_status(:no_content)
    expect(User.find_by(id: customer_id)).to be_nil
  end

  it "does not manage admin accounts through the customer API" do
    other_admin = create(:user, :admin)

    get "/api/v1/admin/customers/#{other_admin.id}", headers: headers

    expect(response).to have_http_status(:not_found)
  end
end
