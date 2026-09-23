require "swagger_helper"

RSpec.describe "Careers API", type: :request do
  let(:career_attributes) { attributes_for(:career) }

  path "/api/v1/careers" do
    post "Submit a job application" do
      tags "Careers"
      consumes "application/json"
      produces "application/json"
      parameter name: :career, in: :body, schema: { "$ref" => "#/components/schemas/CareerRequest" }

      response "201", "application submitted" do
        let(:career) do
          career_attributes.merge(
            cover_letter: "I would love to join the team.",
            resume_link: "https://example.com/resume.pdf",
            opt_in: true
          )
        end

        run_test! do |response|
          payload = JSON.parse(response.body)

          expect(payload).to include(
            "full_name" => career[:full_name],
            "email" => career[:email],
            "phone" => career[:phone],
            "opt_in" => true,
            "experience" => career[:experience],
            "cover_letter" => career[:cover_letter],
            "resume_link" => career[:resume_link]
          )
        end
      end

      response "422", "validation failed" do
        let(:career) { { email: career_attributes[:email] } }

        run_test! do |response|
          expect(JSON.parse(response.body).fetch("errors")).to include(
            "Full name can't be blank",
            "Phone can't be blank",
            "Experience can't be blank"
          )
        end
      end
    end
  end

  it "creates an application from a JSON body" do
    expect {
      post "/api/v1/careers", params: career_attributes, as: :json
    }.to change(Career, :count).by(1)

    expect(response).to have_http_status(:created)
    expect(json_body).to include(
      "full_name" => career_attributes[:full_name],
      "opt_in" => false,
      "cover_letter" => nil
    )
  end

  it "creates an application nested under career" do
    post "/api/v1/careers", params: { career: career_attributes }, as: :json

    expect(response).to have_http_status(:created)
    expect(json_body["full_name"]).to eq(career_attributes[:full_name])
  end

  it "attaches a resume and stores its blob URL" do
    resume_file = Tempfile.new([ "resume", ".pdf" ])
    resume_file.write("%PDF-1.4 fake resume")
    resume_file.rewind

    post "/api/v1/careers", params: career_attributes.merge(
      resume: Rack::Test::UploadedFile.new(resume_file.path, "application/pdf")
    )

    expect(response).to have_http_status(:created)
    expect(json_body["resume_link"]).to match(%r{/rails/active_storage/blobs/})
    expect(Career.last.resume).to be_attached
  ensure
    resume_file&.close!
  end
end
