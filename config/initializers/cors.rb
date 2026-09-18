# Be sure to restart your server when you modify this file.

# Avoid CORS issues when API is called from the frontend app.
# Handle Cross-Origin Resource Sharing (CORS) in order to accept cross-origin Ajax requests.
#
# Set CORS_ORIGINS to a comma-separated list of exact frontend origins (scheme + host + port).
# Example: CORS_ORIGINS=https://dinehub.example.com,https://www.dinehub.example.com
# Requests from any other Origin are rejected (no Access-Control-Allow-Origin header).
#
# Read more: https://github.com/cyu/rack-cors

allowed_origins = ENV.fetch("CORS_ORIGINS") {
  if Rails.env.production?
    ""
  else
    "http://localhost:5173,http://127.0.0.1:5173,http://localhost:3000,http://localhost:3001,https://#{ENV.fetch("APP_HOST")}"
  end
  
}.split(",").map(&:strip).compact_blank.freeze 
 
Rails.application.config.allowed_cors_origins = allowed_origins

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins do |source, _env|
      Rails.application.config.allowed_cors_origins.include?(source)
    end

    resource "/api/*",
      headers: :any,
      methods: %i[get post put patch delete options head],
      credentials: false,
      max_age: 86_400
  end
end
