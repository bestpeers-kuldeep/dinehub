# rswag is only in the development/test Gemfile group.
if defined?(Rswag::Ui)
  Rswag::Ui.configure do |c|
    c.openapi_endpoint "/api-docs/v1/swagger.yaml", "API V1 Docs"
  end
end
