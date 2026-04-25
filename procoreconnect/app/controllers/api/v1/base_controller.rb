module Api
  module V1
    class BaseController < ApplicationController
      include Authenticatable

      rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
      rescue_from ActiveRecord::RecordInvalid, with: :render_unprocessable
      rescue_from ActionController::ParameterMissing, with: :render_bad_request

      private

      def render_not_found(exception = nil)
        render json: { error: exception&.message || "Not found" }, status: :not_found
      end

      def render_unprocessable(exception)
        render json: { errors: exception.record.errors.full_messages }, status: :unprocessable_content
      end

      def render_bad_request(exception)
        render json: { error: exception.message }, status: :bad_request
      end
    end
  end
end
