module Authenticable
  extend ActiveSupport::Concern

  AUTH_COOKIE_NAME = :jwt

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
    token = cookie_token.presence || bearer_token
    return if token.blank?

    payload = JsonWebToken.decode(token)
    return if payload.blank?

    User.find_by(id: payload[:user_id])
  end

  def cookie_token
    cookies[AUTH_COOKIE_NAME]
  end

  def bearer_token
    header = request.headers["Authorization"].to_s
    return if header.blank?

    header.split(" ").last
  end

  def set_auth_cookie(token)
    cookies[AUTH_COOKIE_NAME] = auth_cookie_options.merge(
      value: token,
      expires: JsonWebToken::DEFAULT_EXPIRY.from_now
    )
  end

  def clear_auth_cookie
    cookies.delete(AUTH_COOKIE_NAME, auth_cookie_options)
  end

  def auth_cookie_options
    {
      httponly: true,
      secure: Rails.env.production?,
      same_site: Rails.env.production? ? :none : :lax,
      path: "/"
    }
  end
end
