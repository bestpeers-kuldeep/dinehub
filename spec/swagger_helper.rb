# frozen_string_literal: true

require "rails_helper"
require "yaml"

RSpec.configure do |config|
  config.openapi_root = Rails.root.join("swagger").to_s

  existing_document = YAML.load_file(Rails.root.join("swagger/v1/swagger.yaml")).deep_symbolize_keys
  config.openapi_specs = {
    "v1/swagger.yaml" => existing_document
      .slice(:openapi, :info, :servers, :tags, :components)
      .merge(paths: {})
  }

  config.openapi_format = :yaml
end
