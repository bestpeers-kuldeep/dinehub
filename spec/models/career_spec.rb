require "rails_helper"

RSpec.describe Career, type: :model do
  it "syncs resume_link after a resume is attached" do
    career = create(:career, :with_resume)

    expect(career.reload.resume).to be_attached
    expect(career.resume_link).to be_present
    expect(career.resume_link).to match(%r{/rails/active_storage/blobs/})
  end

  it "leaves resume_link blank when no resume is attached" do
    career = create(:career)

    expect(career.reload.resume_link).to be_nil
  end

  it "keeps an external resume_link when no file is attached" do
    career = create(:career, :with_external_resume)

    expect(career.reload.resume_link).to eq("https://example.com/resume.pdf")
  end
end
