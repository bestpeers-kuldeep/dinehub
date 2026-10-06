require "swagger_helper"

RSpec.describe "Delivery addresses API", type: :request do
  let(:user) { create(:user) }
  let(:Authorization) { "Bearer #{JsonWebToken.encode({ user_id: user.id })}" }
  let(:address_attributes) do
    {
      address_line: "12 Baker Street",
      city: "Mumbai",
      state: "Maharashtra",
      postal_code: "400001",
      landmark: "Near the station",
      is_default: true
    }
  end

  path "/api/v1/delivery_addresses" do
    get "List delivery addresses" do
      tags "Delivery addresses"
      produces "application/json"
      security [ { BearerAuth: [] }, { CookieAuth: [] } ]
      parameter name: :Authorization, in: :header, type: :string, required: false

      response "200", "addresses returned" do
        before { create(:delivery_address, user: user) }

        run_test!
      end

      response "401", "unauthorized" do
        let(:Authorization) { nil }
        run_test!
      end
    end

    post "Create a delivery address" do
      tags "Delivery addresses"
      consumes "application/json"
      produces "application/json"
      security [ { BearerAuth: [] }, { CookieAuth: [] } ]
      parameter name: :Authorization, in: :header, type: :string, required: false
      parameter name: :payload, in: :body, schema: { "$ref" => "#/components/schemas/DeliveryAddressRequest" }

      response "201", "address created" do
        let(:payload) { { delivery_address: address_attributes } }

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body["address_line"]).to eq("12 Baker Street")
          expect(body["is_default"]).to eq(true)
        end
      end

      response "422", "validation failed" do
        let(:payload) { { delivery_address: { city: "Mumbai" } } }
        run_test!
      end
    end
  end

  path "/api/v1/delivery_addresses/{id}" do
    get "Get a delivery address" do
      tags "Delivery addresses"
      produces "application/json"
      security [ { BearerAuth: [] }, { CookieAuth: [] } ]
      parameter name: :Authorization, in: :header, type: :string, required: false
      parameter name: :id, in: :path, type: :integer

      response "200", "address returned" do
        let(:id) { create(:delivery_address, user: user).id }
        run_test!
      end

      response "404", "address not found" do
        let(:id) { 0 }
        run_test!
      end
    end

    patch "Update a delivery address" do
      tags "Delivery addresses"
      consumes "application/json"
      produces "application/json"
      security [ { BearerAuth: [] }, { CookieAuth: [] } ]
      parameter name: :Authorization, in: :header, type: :string, required: false
      parameter name: :id, in: :path, type: :integer
      parameter name: :payload, in: :body, schema: { "$ref" => "#/components/schemas/DeliveryAddressRequest" }

      response "200", "address updated" do
        let(:id) { create(:delivery_address, user: user).id }
        let(:payload) { { delivery_address: address_attributes.merge(address_line: "99 New Street") } }

        run_test! do |response|
          expect(JSON.parse(response.body)["address_line"]).to eq("99 New Street")
        end
      end

      response "422", "validation failed" do
        let(:id) { create(:delivery_address, user: user).id }
        let(:payload) { { delivery_address: { address_line: "" } } }
        run_test!
      end
    end

    delete "Delete a delivery address" do
      tags "Delivery addresses"
      produces "application/json"
      security [ { BearerAuth: [] }, { CookieAuth: [] } ]
      parameter name: :Authorization, in: :header, type: :string, required: false
      parameter name: :id, in: :path, type: :integer

      response "200", "address deleted" do
        let(:id) { create(:delivery_address, user: user).id }

        run_test! do |response|
          expect(JSON.parse(response.body)["message"]).to eq("Delivery address deleted successfully")
        end
      end

      response "404", "address not found" do
        let(:id) { 0 }
        run_test!
      end
    end
  end
end
