require "swagger_helper"

RSpec.describe "Orders", type: :request do
  let(:user) { create(:user) }
  let(:order) { create(:order, user: user, status: :confirmed) }
  let(:Authorization) { "Bearer #{JsonWebToken.encode({ user_id: user.id })}" }

  path "/api/v1/orders" do
    get "List orders" do
      tags "Orders"
      produces "application/json"
      security [ { BearerAuth: [] }, { CookieAuth: [] } ]
      parameter name: :Authorization, in: :header, type: :string, required: false

      response "200", "orders returned" do
        before { create(:order, user: user, status: :confirmed) }

        run_test!
      end

      response "401", "unauthorized" do
        let(:Authorization) { nil }
        run_test!
      end
    end
  end

  path "/api/v1/orders/{id}" do
    get "Get an order" do
      tags "Orders"
      produces "application/json"
      security [ { BearerAuth: [] }, { CookieAuth: [] } ]
      parameter name: :Authorization, in: :header, type: :string, required: false
      parameter name: :id, in: :path, type: :integer

      response "200", "order returned" do
        let(:id) { create(:order, user: user, status: :confirmed).id }
        run_test!
      end

      response "404", "order not found" do
        let(:id) { 0 }
        run_test!
      end
    end

    patch "Update order status" do
      tags "Orders"
      consumes "application/json"
      produces "application/json"
      security [ { BearerAuth: [] }, { CookieAuth: [] } ]
      parameter name: :Authorization, in: :header, type: :string, required: false
      parameter name: :id, in: :path, type: :integer
      parameter name: :payload, in: :body, schema: { "$ref" => "#/components/schemas/OrderStatusRequest" }

      response "200", "status updated" do
        let(:id) { create(:order, user: user, status: :confirmed).id }
        let(:payload) { { status: "preparing" } }

        run_test! do |response|
          expect(JSON.parse(response.body)["status"]).to eq("preparing")
        end
      end

      response "422", "status change is not allowed" do
        let(:id) { create(:order, user: user, status: :confirmed).id }
        let(:payload) { { status: "completed" } }
        run_test!
      end

      response "404", "order not found" do
        let(:id) { 0 }
        let(:payload) { { status: "preparing" } }
        run_test!
      end
    end
  end

  path "/api/v1/orders/{order_id}/delivery" do
    get "Get the delivery for an order" do
      tags "Deliveries"
      produces "application/json"
      security [ { BearerAuth: [] }, { CookieAuth: [] } ]
      parameter name: :Authorization, in: :header, type: :string, required: false
      parameter name: :order_id, in: :path, type: :integer

      response "200", "delivery returned" do
        let(:delivered_order) { create(:order, user: user, status: :confirmed) }
        let(:order_id) { delivered_order.id }

        before { create(:delivery, order: delivered_order, provider: "borzo", status: :requested) }

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body["order_id"]).to eq(delivered_order.id)
          expect(body["status"]).to eq("requested")
        end
      end

      response "404", "order not found" do
        let(:order_id) { 0 }
        run_test!
      end
    end
  end

  def sign_in
    cookies[:jwt] = JsonWebToken.encode({ user_id: user.id })
  end

  it "does not expose order creation" do
    sign_in

    post "/api/v1/orders", params: { cart_id: order.cart_id }.to_json,
                           headers: { "CONTENT_TYPE" => "application/json" }

    expect(response).to have_http_status(:not_found)
  end

  it "moves an order forward through the kitchen statuses" do
    sign_in

    patch "/api/v1/orders/#{order.id}",
          params: { status: "preparing" }.to_json,
          headers: { "CONTENT_TYPE" => "application/json" }

    expect(response).to have_http_status(:ok)
    expect(order.reload).to be_preparing

    patch "/api/v1/orders/#{order.id}",
          params: { status: "ready" }.to_json,
          headers: { "CONTENT_TYPE" => "application/json" }

    expect(order.reload).to be_ready
  end

  it "rejects a status jump and a backward move" do
    sign_in

    patch "/api/v1/orders/#{order.id}",
          params: { status: "completed" }.to_json,
          headers: { "CONTENT_TYPE" => "application/json" }

    expect(response).to have_http_status(:unprocessable_entity)
    expect(order.reload).to be_confirmed
  end
end
