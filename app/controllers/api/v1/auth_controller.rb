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
          set_auth_cookie(JsonWebToken.encode({ user_id: user.id }))
          render json: { user: user.as_public_json }
        else
          render json: { error: "Invalid email or password" }, status: :unauthorized
        end
      end

      def logout
        clear_auth_cookie
        head :no_content
      end

      def me
        render json: current_user.as_public_json
      end

      def forgot_password
        email = forgot_password_params[:email].to_s.strip.downcase
        if email.blank?
          render json: { errors: [ "Email can't be blank" ] }, status: :unprocessable_entity
          return
        end

        user = User.find_by(email: email)
        if user
          user.send_reset_password_instructions
          render json: { message: "Password reset instructions sent to email" }
        else
          render json: { error: "Email not found" }, status: :not_found
        end
      end

      def reset_password
        token = reset_password_params[:token].to_s
        password = reset_password_params[:password]
        password_confirmation = reset_password_params[:password_confirmation]

        if token.blank? || password.blank?
          render json: { errors: [ "Token and password are required" ] }, status: :unprocessable_entity
          return
        end

        user = User.find_by_reset_password_token(token)
        unless user&.reset_password_period_valid?
          render json: { error: "Reset token is invalid or expired" }, status: :unprocessable_entity
          return
        end

        user.reset_password!(password: password, password_confirmation: password_confirmation)
        render json: { message: "Password has been reset" }
      rescue ActiveRecord::RecordInvalid => e
        render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
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

      def forgot_password_params
        if params[:user].present?
          params.require(:user).permit(:email)
        else
          params.permit(:email)
        end
      end

      def reset_password_params
        permitted = %i[token password password_confirmation]
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
