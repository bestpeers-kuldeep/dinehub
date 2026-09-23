module Api
  module V1
    class AuthController < BaseController
      before_action :authenticate_user!, only: :me

      def register
        user = User.create!(user_params)
        render json: auth_payload(user), status: :created
      rescue ActiveRecord::RecordInvalid => e
        render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
      end

      def login
        user = User.find_by(email: login_params[:email].to_s.strip.downcase)
        if user&.authenticate(login_params[:password])
          render json: auth_payload(user)
        else
          render json: { error: "Invalid email or password" }, status: :unauthorized
        end
      end

      def me
        render json: current_user.as_public_json
      end

      private

      def user_params
        permitted = %i[first_name last_name email phone password]
        if params[:user].present?
          params.require(:user).permit(permitted)
        else
          params.permit(permitted)
        end
      end

      def login_params
        permitted = %i[email password]
        if params[:user].present?
          params.require(:user).permit(permitted)
        else
          params.permit(permitted)
        end
      end

      def auth_payload(user)
        {
          token: JsonWebToken.encode({ user_id: user.id }),
          user: user.as_public_json
        }
      end
    end
  end
end
