require "test_helper"

class CareerTest < ActiveSupport::TestCase
  test "syncs resume_link after a resume is attached" do
    career = Career.create!(
      full_name: "Alex Guest",
      email: "alex@example.com",
      phone: "555-0100",
      experience: "5 years front of house"
    )

    career.resume.attach(
      io: StringIO.new("%PDF-1.4 fake resume"),
      filename: "resume.pdf",
      content_type: "application/pdf"
    )

    career.reload
    assert career.resume.attached?
    assert_not_nil career.resume_link
    assert_match %r{/rails/active_storage/blobs/}, career.resume_link
  end

  test "leaves resume_link blank when no resume is attached" do
    career = Career.create!(
      full_name: "Alex Guest",
      email: "alex@example.com",
      phone: "555-0100",
      experience: "5 years front of house"
    )

    assert_nil career.reload.resume_link
  end

  test "keeps an external resume_link when no file is attached" do
    career = Career.create!(
      full_name: "Alex Guest",
      email: "alex@example.com",
      phone: "555-0100",
      experience: "5 years front of house",
      resume_link: "https://example.com/resume.pdf"
    )

    assert_equal "https://example.com/resume.pdf", career.reload.resume_link
  end
end
