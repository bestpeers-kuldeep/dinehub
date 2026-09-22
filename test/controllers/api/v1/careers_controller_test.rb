require "test_helper"

class Api::V1::CareersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @params = {
      full_name: "Alex Guest",
      email: "alex@example.com",
      phone: "555-0100",
      experience: "5 years front of house"
    }
  end

  test "creates a career application" do
    assert_difference -> { Career.count }, 1 do
      post "/api/v1/careers", params: @params.merge(
        cover_letter: "I would love to join the team.",
        resume_link: "https://example.com/resume.pdf",
        opt_in: true
      )
    end

    assert_response :created
    body = JSON.parse(response.body)
    assert_equal "Alex Guest", body["full_name"]
    assert_equal "alex@example.com", body["email"]
    assert_equal "555-0100", body["phone"]
    assert_equal true, body["opt_in"]
    assert_equal "5 years front of house", body["experience"]
    assert_equal "I would love to join the team.", body["cover_letter"]
    assert_equal "https://example.com/resume.pdf", body["resume_link"]
  end

  test "creates a career application from a json body" do
    post "/api/v1/careers", params: @params, as: :json

    assert_response :created
    body = JSON.parse(response.body)
    assert_equal "Alex Guest", body["full_name"]
    assert_equal false, body["opt_in"]
    assert_nil body["cover_letter"]
  end

  test "creates a career application nested under career" do
    post "/api/v1/careers", params: { career: @params }, as: :json

    assert_response :created
    assert_equal "Alex Guest", JSON.parse(response.body)["full_name"]
  end

  test "attaches a resume and stores the blob url" do
    resume_file = Tempfile.new([ "resume", ".pdf" ])
    resume_file.write("%PDF-1.4 fake resume")
    resume_file.rewind

    post "/api/v1/careers", params: @params.merge(
      resume: Rack::Test::UploadedFile.new(resume_file.path, "application/pdf")
    )

    assert_response :created
    body = JSON.parse(response.body)
    assert_match %r{/rails/active_storage/blobs/}, body["resume_link"]

    career = Career.last
    assert career.resume.attached?
  ensure
    resume_file.close!
  end

  test "rejects a career application without required fields" do
    post "/api/v1/careers", params: { email: "alex@example.com" }

    assert_response :unprocessable_entity
    errors = JSON.parse(response.body)["errors"]
    assert_includes errors, "Full name can't be blank"
    assert_includes errors, "Phone can't be blank"
    assert_includes errors, "Experience can't be blank"
  end
end
