class MenuItem < ApplicationRecord
  include AttachmentUrl

  belongs_to :menu_category

  has_one_attached :image

  delegate :drink_type, to: :menu_category, allow_nil: true

  after_commit :sync_image_url, on: %i[create update]

  scope :for_drink_type, ->(drink_type) {
    joins(:menu_category).where(menu_categories: { drink_type: drink_type })
  }

  # Items whose [start_at, end_at] overlaps the given date range (inclusive).
  # NULL bounds are treated as open-ended.
  scope :active_between, ->(start_date, end_date) {
    where(
      "(start_at IS NULL OR start_at::date <= ?) AND (end_at IS NULL OR end_at::date >= ?)",
      end_date, start_date
    )
  }

  private

  def sync_image_url
    return unless image.attached?

    url = synced_attachment_url(image)
    update_column(:image_url, url) if image_url != url
  end
end
