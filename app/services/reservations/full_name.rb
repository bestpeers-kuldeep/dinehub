module Reservations
  module FullName
    def self.from(attributes)
      attrs = attributes.to_h.stringify_keys
      return attrs["full_name"].to_s.strip if attrs["full_name"].present?

      [ attrs["first_name"], attrs["last_name"] ]
        .map { |part| part.to_s.strip }
        .reject(&:blank?)
        .join(" ")
    end

    def self.assign(attributes)
      attrs = attributes.to_h.stringify_keys
      attrs.except("first_name", "last_name").merge("full_name" => from(attrs))
    end
  end
end
