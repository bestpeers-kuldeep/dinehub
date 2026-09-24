class EventItem < ApplicationRecord
  include AttachmentUrl

  belongs_to :event

  has_one_attached :logo

  validates :title, presence: true
  validates :event_date, presence: true

  after_commit :sync_logo_url, on: %i[create update]

  private

  def sync_logo_url
    return unless logo.attached?

    url = synced_attachment_url(logo)
    update_column(:logo_url, url) if logo_url != url
  end
end
