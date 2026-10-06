require "swagger_helper"

RSpec.describe "Cart API", type: :request do
  let(:user) { create(:user) }
  let(:Authorization) { "Bearer #{JsonWebToken.encode({ user_id: user.id })}" }

  path "/api/v1/cart" do
    get "Get the current cart" do
      tags "Cart"
      produces "application/json"
      security [ { BearerAuth: [] }, { CookieAuth: [] } ]
      parameter name: :Authorization, in: :header, type: :string, required: false

      response "200", "cart returned" do
        before { create(:cart_item, cart: create(:cart, user: user)) }

        schema "$ref" => "#/components/schemas/Cart"
        run_test!
      end

      response "401", "unauthorized" do
        let(:Authorization) { nil }
        run_test!
      end
    end

    delete "Clear the current cart" do
      tags "Cart"
      produces "application/json"
      security [ { BearerAuth: [] }, { CookieAuth: [] } ]
      parameter name: :Authorization, in: :header, type: :string, required: false

      response "200", "cart cleared" do
        before { create(:cart, user: user) }

        run_test! do |response|
          expect(JSON.parse(response.body)["message"]).to eq("Cart cleared successfully")
        end
      end

      response "422", "cart is checked out" do
        before do
          cart = create(:cart, user: user)
          create(:payment, cart: cart, order: nil, status: :pending)
        end

        run_test!
      end

      response "401", "unauthorized" do
        let(:Authorization) { nil }
        run_test!
      end
    end
  end

  path "/api/v1/cart/items" do
    post "Add items to the cart" do
      tags "Cart"
      consumes "application/json"
      produces "application/json"
      security [ { BearerAuth: [] }, { CookieAuth: [] } ]
      parameter name: :Authorization, in: :header, type: :string, required: false
      parameter name: :payload, in: :body, schema: { "$ref" => "#/components/schemas/CartItemsRequest" }

      response "201", "items added" do
        let(:menu_item) { create(:menu_item) }
        let(:payload) { { cart_items: [ { menu_item_id: menu_item.id, quantity: 2 } ] } }

        run_test! do |response|
          item = JSON.parse(response.body).first
          expect(item["menu_item_id"]).to eq(menu_item.id)
          expect(item["quantity"]).to eq(2)
        end
      end

      response "404", "menu item not found" do
        let(:payload) { { cart_items: [ { menu_item_id: 0, quantity: 1 } ] } }
        run_test!
      end

      response "422", "cart is checked out" do
        let(:menu_item) { create(:menu_item) }
        let(:payload) { { cart_items: [ { menu_item_id: menu_item.id, quantity: 1 } ] } }

        before do
          cart = create(:cart, user: user)
          create(:payment, cart: cart, order: nil, status: :pending)
        end

        run_test!
      end

      response "401", "unauthorized" do
        let(:Authorization) { nil }
        let(:payload) { { cart_items: [] } }
        run_test!
      end
    end
  end

  path "/api/v1/cart/items/{id}" do
    patch "Update a cart item quantity" do
      tags "Cart"
      consumes "application/json"
      produces "application/json"
      security [ { BearerAuth: [] }, { CookieAuth: [] } ]
      parameter name: :Authorization, in: :header, type: :string, required: false
      parameter name: :id, in: :path, type: :integer
      parameter name: :payload, in: :body, schema: { "$ref" => "#/components/schemas/CartItemUpdateRequest" }

      response "200", "quantity updated" do
        let(:cart_item) { create(:cart_item, cart: create(:cart, user: user), quantity: 1) }
        let(:id) { cart_item.id }
        let(:payload) { { cart_item: { quantity: 3 } } }

        run_test! do |response|
          expect(JSON.parse(response.body)["quantity"]).to eq(3)
        end
      end

      response "422", "quantity is invalid" do
        let(:cart_item) { create(:cart_item, cart: create(:cart, user: user)) }
        let(:id) { cart_item.id }
        let(:payload) { { cart_item: { quantity: 0 } } }
        run_test!
      end

      response "404", "cart item not found" do
        let(:id) { 0 }
        let(:payload) { { cart_item: { quantity: 1 } } }
        run_test!
      end
    end

    delete "Remove a cart item" do
      tags "Cart"
      produces "application/json"
      security [ { BearerAuth: [] }, { CookieAuth: [] } ]
      parameter name: :Authorization, in: :header, type: :string, required: false
      parameter name: :id, in: :path, type: :integer

      response "200", "item removed" do
        let(:id) { create(:cart_item, cart: create(:cart, user: user)).id }

        run_test! do |response|
          expect(JSON.parse(response.body)["message"]).to eq("Item removed from cart")
        end
      end

      response "404", "cart item not found" do
        let(:id) { 0 }
        run_test!
      end
    end
  end
end
