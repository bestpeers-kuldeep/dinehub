module Authorizable
  extend ActiveSupport::Concern

  included do
    class_attribute :required_permission, instance_accessor: false
  end

  class_methods do
    def requires_permission(permission)
      self.required_permission = permission.to_s
    end
  end

  private

  def authorize_permission!
    permission = self.class.required_permission
    return if permission.present? && current_user&.permission?(permission)

    render json: { error: "Forbidden" }, status: :forbidden
  end
end
