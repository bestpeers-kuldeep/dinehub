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
end
