require "rails_helper"

# These specs bypass Active Record validations on purpose (insert_all! /
# update_columns) to prove the database enforces the invariants on its own.
RSpec.describe "Checkout database constraints", type: :model do
  let(:user) { create(:user) }

  # A failed statement aborts the surrounding PostgreSQL transaction, and
  # transactional fixtures keep one open for the whole example. Run each
  # offending statement in a savepoint so the rest of the example can go on.
  def expect_violation(error_class, &block)
    expect { ActiveRecord::Base.transaction(requires_new: true, &block) }.to raise_error(error_class)
  end

  describe "orders" do
    it "requires a cart" do
      expect_violation(ActiveRecord::NotNullViolation) do
        Order.insert_all!([ { user_id: user.id, cart_id: nil, subtotal: 1, tax: 0, total: 1, status: 0 } ])
      end
    end

    it "rejects negative amounts" do
      order = create(:order, user: user)

      expect_violation(ActiveRecord::CheckViolation) { order.update_columns(subtotal: -1) }
      expect_violation(ActiveRecord::CheckViolation) { order.update_columns(tax: -1) }
      expect_violation(ActiveRecord::CheckViolation) { order.update_columns(total: -1) }
    end
  end

  describe "payments" do
    let(:order) { create(:order, user: user) }

    it "allows only one payment per order" do
      create(:payment, order: order)

      expect_violation(ActiveRecord::RecordNotUnique) do
        Payment.insert_all!([ {
          order_id: order.id, cart_id: order.cart_id, gateway: "cashfree", amount: 1, currency: "INR", status: 0,
          gateway_order_id: "ORDER_dup", metadata: {}
        } ])
      end
    end

    it "allows a checkout payment before an order exists" do
      cart = create(:cart, user: user)

      expect { create(:payment, cart: cart, order: nil) }.not_to raise_error
    end

    it "allows only one open checkout per cart" do
      cart = create(:cart, user: user)
      create(:payment, cart: cart, order: nil, status: :pending)

      expect_violation(ActiveRecord::RecordNotUnique) do
        Payment.insert_all!([ {
          cart_id: cart.id, order_id: nil, gateway: "cashfree", amount: 1, currency: "INR", status: 0,
          gateway_order_id: "CHECKOUT_dup", metadata: {}
        } ])
      end
    end

    it "rejects a non-positive amount" do
      payment = create(:payment, order: order)

      expect_violation(ActiveRecord::CheckViolation) { payment.update_columns(amount: 0) }
    end
  end

  describe "carts" do
    it "allows only one live cart per user" do
      create(:cart, user: user)

      expect_violation(ActiveRecord::RecordNotUnique) do
        Cart.insert_all!([ { user_id: user.id, status: 0 } ])
      end
    end

    it "allows a new live cart once the previous one is completed or cleared" do
      first = create(:cart, user: user)
      first.update_columns(status: Cart.statuses[:completed], deleted_at: Time.current)

      expect { create(:cart, user: user) }.not_to raise_error
    end
  end

  describe "delivery_addresses" do
    it "requires the core address fields" do
      %i[address_line city state postal_code].each do |column|
        attrs = attributes_for(:delivery_address).merge(user_id: user.id, column => nil)

        expect_violation(ActiveRecord::NotNullViolation) { DeliveryAddress.insert_all!([ attrs ]) }
      end
    end

    it "allows only one default address per user" do
      create(:delivery_address, user: user, is_default: true)
      other = create(:delivery_address, user: user, is_default: false)

      expect_violation(ActiveRecord::RecordNotUnique) { other.update_columns(is_default: true) }
    end

    it "rejects out-of-range coordinates" do
      address = create(:delivery_address, user: user)

      expect_violation(ActiveRecord::CheckViolation) { address.update_columns(latitude: 91) }
      expect_violation(ActiveRecord::CheckViolation) { address.update_columns(longitude: -181) }
      expect { address.update_columns(latitude: 19.076, longitude: 72.8777) }.not_to raise_error
    end
  end

  describe "deliveries" do
    it "allows only one delivery per order" do
      delivery = create(:delivery)

      expect_violation(ActiveRecord::RecordNotUnique) do
        Delivery.insert_all!([ { order_id: delivery.order_id, status: 0 } ])
      end
    end

    it "defaults status to pending" do
      result = Delivery.insert_all!([ { order_id: create(:order).id } ], returning: %w[id])

      expect(Delivery.find(result.first["id"])).to be_pending
    end
  end

  describe "delivery_events" do
    let(:delivery) { create(:delivery) }

    it "requires an event type" do
      expect_violation(ActiveRecord::NotNullViolation) do
        DeliveryEvent.insert_all!([ { delivery_id: delivery.id, event_type: nil } ])
      end
    end

    it "stores each external event once per delivery" do
      create(:delivery_event, delivery: delivery, external_event_id: "evt_1")

      expect_violation(ActiveRecord::RecordNotUnique) do
        DeliveryEvent.insert_all!([ { delivery_id: delivery.id, event_type: "x", external_event_id: "evt_1" } ])
      end
    end

    it "allows many events without an external id" do
      expect {
        2.times { create(:delivery_event, delivery: delivery, external_event_id: nil) }
      }.not_to raise_error
    end
  end
end
