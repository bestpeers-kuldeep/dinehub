module Api
  module V1
    class BaseController < ApplicationController
      include Authenticable

      # JSON bodies are read as sent. Rails' automatic wrapping would drop
      # first_name/last_name, which are request-only fields with no column.
      wrap_parameters false
    end
  end
end
