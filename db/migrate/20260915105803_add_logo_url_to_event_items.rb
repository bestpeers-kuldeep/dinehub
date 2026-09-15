class AddLogoUrlToEventItems < ActiveRecord::Migration[8.1]
  def change
    add_column :event_items, :logo_url, :string
  end
end
