# frozen_string_literal: true

module Api
  module V1
    class BaseController < ActionController::API
      before_action :authenticate_user!

      rescue_from ActiveRecord::RecordNotFound, with: :not_found
      rescue_from ActiveRecord::RecordInvalid, with: :unprocessable_entity
      rescue_from ActionController::ParameterMissing, with: :bad_request
      rescue_from JWT::DecodeError, with: :unauthorized
      rescue_from JWT::ExpiredSignature, with: :token_expired

      private

      def authenticate_user!
        token = extract_token_from_header
        raise JWT::DecodeError, "Missing token" if token.blank?

        decoded = JwtService.decode(token)
        @current_user = User.find(decoded[:user_id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: { code: "UNAUTHORIZED", message: "Invalid token" } }, status: :unauthorized
      end

      def current_user
        @current_user
      end

      def extract_token_from_header
        header = request.headers["Authorization"]
        return nil unless header

        header.split(" ").last
      end

      # Error handlers
      def not_found(exception)
        render json: {
          error: {
            code: "NOT_FOUND",
            message: exception.message
          }
        }, status: :not_found
      end

      def unprocessable_entity(exception)
        render json: {
          error: {
            code: "UNPROCESSABLE_ENTITY",
            message: "Validation failed",
            details: exception.record&.errors&.messages || {}
          }
        }, status: :unprocessable_entity
      end

      def bad_request(exception)
        render json: {
          error: {
            code: "BAD_REQUEST",
            message: exception.message
          }
        }, status: :bad_request
      end

      def unauthorized(exception)
        render json: {
          error: {
            code: "UNAUTHORIZED",
            message: exception.message || "Invalid token"
          }
        }, status: :unauthorized
      end

      def token_expired(_exception)
        render json: {
          error: {
            code: "TOKEN_EXPIRED",
            message: "Access token has expired. Please refresh."
          }
        }, status: :unauthorized
      end
    end
  end
end
