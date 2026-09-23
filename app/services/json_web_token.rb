class JsonWebToken
  ALGORITHM = "HS256"
  DEFAULT_EXPIRY = 24.hours

  def self.encode(payload, exp: DEFAULT_EXPIRY.from_now)
    JWT.encode(payload.merge(exp: exp.to_i), secret, ALGORITHM)
  end

  def self.decode(token)
    body, = JWT.decode(token, secret, true, { algorithm: ALGORITHM })
    ActiveSupport::HashWithIndifferentAccess.new(body)
  rescue JWT::DecodeError
    nil
  end

  def self.secret
    ENV.fetch("JWT_SECRET") { Rails.application.secret_key_base }
  end
  private_class_method :secret
end
