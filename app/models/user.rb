class User < ApplicationRecord
  has_secure_password

  normalizes :email, with: ->(email) { email.strip.downcase }

  validates :first_name, :last_name, :email, :phone, presence: true
  validates :email, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :phone, uniqueness: true
  validates :password, length: { minimum: 8 }, allow_nil: true

  def as_public_json
    {
      id: id,
      first_name: first_name,
      last_name: last_name,
      full_name: "#{first_name} #{last_name}",
      email: email,
      phone: phone
    }
  end

  def send_reset_password_instructions
    raw_token = SecureRandom.urlsafe_base64(24)
    update!(
      reset_password_token: Digest::SHA256.hexdigest(raw_token),
      reset_password_sent_at: Time.current
    )
    UserMailer.reset_password_instructions(self, raw_token).deliver_later
    raw_token
  end

  def reset_password_url(raw_token)
    host = ENV.fetch("FRONTEND_HOST", ENV.fetch("APP_HOST", "localhost:5173"))
    protocol = ENV.fetch("APP_PROTOCOL", Rails.env.production? ? "https" : "http")
    "#{protocol}://#{host}/reset-password?token=#{raw_token}"
  end
end
