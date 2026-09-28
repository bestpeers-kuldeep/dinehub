# All Administrate controllers inherit from this
# `Administrate::ApplicationController`, making it the ideal place to put
# authentication logic or other before_actions.
module Admin
  class ApplicationController < Administrate::ApplicationController
    before_action :authenticate_admin

    def authenticate_admin
      authenticate_or_request_with_http_basic("Dinehub Admin") do |email, password|
        administrator = Administrator.find_by(email: email.to_s.strip.downcase)
        administrator&.authenticate(password)
      end
    end

    def resource_params
      params.require(resource_class.model_name.param_key)
        .permit(dashboard.permitted_attributes(action_name))
        .tap do |permitted|
          %i[password password_confirmation].each do |attr|
            permitted.delete(attr) if permitted[attr].blank?
          end
        end
    end
  end
end
