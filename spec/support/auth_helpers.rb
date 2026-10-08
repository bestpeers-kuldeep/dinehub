module AuthHelpers
  def auth_headers_for(user)
    token = JsonWebToken.encode({ user_id: user.id })
    { "Authorization" => "Bearer #{token}" }
  end
end

RSpec.configure do |config|
  config.include AuthHelpers, type: :request
end
