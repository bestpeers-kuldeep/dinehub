module Api
  module V1
    module Admin
      class CustomersController < BaseController
        requires_permission "customers.manage"

        before_action :set_customer, only: %i[show update destroy]

        def index
          render_collection(User.customer.order(created_at: :desc)) { |customers| customers.map(&:as_public_json) }
        end

        def show
          render json: @customer.as_public_json
        end

        def create
          customer = User.create!(customer_attributes.merge(role: :customer))
          render json: customer.as_public_json, status: :created
        rescue ActiveRecord::RecordInvalid => e
          render_validation_error(e)
        end

        def update
          @customer.update!(customer_attributes)
          render json: @customer.as_public_json
        rescue ActiveRecord::RecordInvalid => e
          render_validation_error(e)
        end

        def destroy
          @customer.destroy!
          head :no_content
        rescue ActiveRecord::RecordNotDestroyed, ActiveRecord::InvalidForeignKey => e
          render json: { errors: [ e.message ] }, status: :unprocessable_entity
        end

        private

        def set_customer
          @customer = User.customer.find(params[:id])
        end

        def customer_attributes
          attributes = resource_params(
            :first_name, :last_name, :email, :phone, :additional_phone, :password,
            key: :customer
          ).to_h
          attributes.delete("password") if attributes["password"].blank?
          attributes
        end
      end
    end
  end
end
