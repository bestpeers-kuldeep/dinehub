module Api
  module V1
    class CareersController < BaseController
      def create
        career = Career.new(career_attributes)
        career.resume.attach(resume_file) if resume_file.present?
        career.save!

        render json: career.as_public_json, status: :created
      rescue ActiveRecord::RecordInvalid => e
        render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
      rescue StandardError => e
        render json: { error: e.message }, status: :internal_server_error
      end

      private

      def career_params
        permitted = %i[full_name email phone opt_in experience cover_letter resume_link resume]
        if params[:career].present?
          params.require(:career).permit(permitted)
        else
          params.permit(permitted)
        end
      end

      def career_attributes
        career_params.except(:resume)
      end

      def resume_file
        career_params[:resume]
      end
    end
  end
end
