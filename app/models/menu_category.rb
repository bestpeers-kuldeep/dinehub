class MenuCategory < ApplicationRecord
  belongs_to :menu
  has_one_attached :image
  has_many :menu_items, dependent: :destroy

  enum :drink_type, { beer: 0, wine: 1, cocktails: 2, spirits: 3, whiskey: 4 }, allow_nil: true

  after_commit :sync_image_url, on: %i[create update]

  private

  def sync_image_url
    return unless image.attached?

    url = Rails.application.routes.url_helpers.rails_blob_url(image)
    update_column(:image_url, url) if image_url != url
  end
end
