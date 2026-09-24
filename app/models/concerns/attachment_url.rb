module AttachmentUrl
  extend ActiveSupport::Concern

  private

  def synced_attachment_url(attachment)
    return unless attachment.attached?

    blob = attachment.blob
    if blob.service_name.to_s == "cloudinary"
      blob.service.url(blob.key, filename: blob.filename, content_type: blob.content_type)
    else
      Rails.application.routes.url_helpers.rails_blob_url(attachment)
    end
  end
end
