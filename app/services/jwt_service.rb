# frozen_string_literal: true

class JwtService
  ALGORITHM = "HS256"
  SECRET_KEY = ENV.fetch("JWT_SECRET_KEY", Rails.application.secret_key_base)

  class << self
    # Encode an access token
    def encode(payload, exp: 15.minutes.from_now.to_i)
      payload[:exp] = exp
      payload[:iat] = Time.current.to_i
      JWT.encode(payload, SECRET_KEY, ALGORITHM)
    end

    # Encode a refresh token
    def encode_refresh(payload, exp: 7.days.from_now.to_i)
      payload[:exp] = exp
      payload[:iat] = Time.current.to_i
      payload[:type] = "refresh"
      JWT.encode(payload, SECRET_KEY, ALGORITHM)
    end

    # Decode and validate a token
    def decode(token)
      decoded = JWT.decode(token, SECRET_KEY, true, {
        algorithm: ALGORITHM,
        verify_expiration: true
      })

      HashWithIndifferentAccess.new(decoded.first)
    rescue JWT::ExpiredSignature
      raise JWT::ExpiredSignature, "Token has expired"
    rescue JWT::DecodeError => e
      raise JWT::DecodeError, "Invalid token: #{e.message}"
    end
  end
end
