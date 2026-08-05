# frozen_string_literal: true

module Api
  module V1
    class AuthController < ActionController::API
      def login
        user = User.find_by(email: params[:email])

        if user&.authenticate(params[:password])
          access_token = JwtService.encode(user_id: user.id, exp: 15.minutes.from_now.to_i)
          refresh_token = JwtService.encode_refresh(user_id: user.id, exp: 7.days.from_now.to_i)

          user.update!(refresh_token: refresh_token)

          render json: {
            access_token: access_token,
            refresh_token: refresh_token,
            user: {
              id: user.id,
              email: user.email,
              name: user.name
            }
          }
        else
          render json: {
            error: {
              code: "UNAUTHORIZED",
              message: "Invalid email or password"
            }
          }, status: :unauthorized
        end
      end

      def refresh
        refresh_token = params[:refresh_token]

        if refresh_token.blank?
          render json: {
            error: {
              code: "BAD_REQUEST",
              message: "Refresh token is required"
            }
          }, status: :bad_request
          return
        end

        decoded = JwtService.decode(refresh_token)
        user = User.find(decoded[:user_id])

        # Verify the refresh token matches the stored one
        if user.refresh_token != refresh_token
          render json: {
            error: {
              code: "UNAUTHORIZED",
              message: "Invalid refresh token"
            }
          }, status: :unauthorized
          return
        end

        # Generate new tokens (rotation)
        new_access_token = JwtService.encode(user_id: user.id, exp: 15.minutes.from_now.to_i)
        new_refresh_token = JwtService.encode_refresh(user_id: user.id, exp: 7.days.from_now.to_i)

        user.update!(refresh_token: new_refresh_token)

        render json: {
          access_token: new_access_token,
          refresh_token: new_refresh_token
        }
      rescue JWT::DecodeError, JWT::ExpiredSignature
        render json: {
          error: {
            code: "UNAUTHORIZED",
            message: "Invalid or expired refresh token"
          }
        }, status: :unauthorized
      end

      def logout
        # Extract token and invalidate refresh token
        header = request.headers["Authorization"]
        token = header&.split(" ")&.last

        if token
          decoded = JwtService.decode(token)
          user = User.find(decoded[:user_id])
          user.update!(refresh_token: nil)
        end

        render json: { message: "Logged out successfully" }
      rescue JWT::DecodeError, JWT::ExpiredSignature
        # Even if token is expired, return success for logout
        render json: { message: "Logged out successfully" }
      end
    end
  end
end
