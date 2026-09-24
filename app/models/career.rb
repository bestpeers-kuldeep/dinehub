class Career < ApplicationRecord
  include AttachmentUrl

  has_one_attached :resume

  validates :full_name, :email, :phone, :experience, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }

  after_commit :sync_resume_link, on: %i[create update]

  def as_public_json
    {
      id: id,
      full_name: full_name,
      email: email,
      phone: phone,
      opt_in: opt_in,
      experience: experience,
      cover_letter: cover_letter,
      resume_link: resume_link
    }
  end

  private

  def sync_resume_link
    return unless resume.attached?

    url = synced_attachment_url(resume)
    update_column(:resume_link, url) if resume_link != url
  end
end
