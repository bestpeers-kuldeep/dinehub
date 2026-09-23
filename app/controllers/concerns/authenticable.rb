module Authenticable
  extend ActiveSupport::Concern

  def current_user
    return @current_user if defined?(@current_user)

    @current_user = user_from_token
  end

  def authenticate_user!
    return if current_user

    render json: { error: "Unauthorized" }, status: :unauthorized
  end

  private

  def user_from_token
    token = bearer_token
    return if token.blank?

    payload = JsonWebToken.decode(token)
    return if payload.blank?

    User.find_by(id: payload[:user_id])
  end

  def bearer_token
    header = request.headers["Authorization"].to_s
    return if header.blank?

    header.split(" ").last
  end
end
