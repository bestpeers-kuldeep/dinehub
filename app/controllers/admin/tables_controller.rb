module Admin
  class TablesController < Admin::ApplicationController
    def available
      @tables = Table.all
      @tables = @tables.where()
    end
  end
end
