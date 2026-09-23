class User < ApplicationRecord
  RESET_PASSWORD_PERIOD = 1.hours

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
    host = ENV.fetch("FRONTEND_HOST", "localhost:3000")
    protocol = ENV.fetch("APP_PROTOCOL", Rails.env.production? ? "https" : "http")
    "#{protocol}://#{host}/reset_password?token=#{raw_token}"
  end

  def self.find_by_reset_password_token(raw_token)
    return if raw_token.blank?

    find_by(reset_password_token: Digest::SHA256.hexdigest(raw_token.to_s))
  end

  def reset_password_period_valid?
    reset_password_sent_at.present? && reset_password_sent_at >= RESET_PASSWORD_PERIOD.ago
  end

  def reset_password!(password:, password_confirmation: nil)
    if password_confirmation.present? && password != password_confirmation
      errors.add(:password_confirmation, "doesn't match Password")
      raise ActiveRecord::RecordInvalid, self
    end

    update!(
      password: password,
      reset_password_token: nil,
      reset_password_sent_at: nil
    )
  end
end
