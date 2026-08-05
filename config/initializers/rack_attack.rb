# frozen_string_literal: true

# Rack::Attack configuration for rate limiting
Rack::Attack.throttle("requests/ip", limit: 100, period: 1.minute) do |req|
  req.ip unless req.path.start_with?("/assets", "/health")
end

# Throttle login attempts by IP
Rack::Attack.throttle("logins/ip", limit: 5, period: 30.seconds) do |req|
  if req.path == "/api/v1/auth/login" && req.post?
    req.ip
  end
end

# Throttle authenticated requests by user ID
Rack::Attack.throttle("authenticated_requests", limit: 300, period: 5.minutes) do |req|
  if req.path.start_with?("/api/v1/")
    # Extract user ID from JWT token if present
    header = req.env["HTTP_AUTHORIZATION"]
    if header
      token = header.split(" ").last
      begin
        decoded = JWT.decode(token, ENV.fetch("JWT_SECRET_KEY", Rails.application.secret_key_base), true, { algorithm: "HS256" })
        decoded.first["user_id"].to_s
      rescue JWT::DecodeError, JWT::ExpiredSignature
        nil
      end
    end
  end
end

# Throttle task creation
Rack::Attack.throttle("task_creation", limit: 20, period: 1.minute) do |req|
  if req.path == "/api/v1/tasks" && req.post?
    # Use user ID if authenticated, otherwise IP
    header = req.env["HTTP_AUTHORIZATION"]
    if header
      token = header.split(" ").last
      begin
        decoded = JWT.decode(token, ENV.fetch("JWT_SECRET_KEY", Rails.application.secret_key_base), true, { algorithm: "HS256" })
        "user:#{decoded.first['user_id']}"
      rescue JWT::DecodeError, JWT::ExpiredSignature
        req.ip
      end
    else
      req.ip
    end
  end
end

# Custom response for throttled requests
Rack::Attack.throttled_responder = lambda do |request|
  match_data = request.env["rack.attack.match_data"]
  now = Time.current

  headers = {
    "Content-Type" => "application/json",
    "Retry-After" => (match_data[:period] - (now.to_i % match_data[:period])).to_s
  }

  body = {
    error: {
      code: "TOO_MANY_REQUESTS",
      message: "Rate limit exceeded. Try again later.",
      retry_after: match_data[:period] - (now.to_i % match_data[:period])
    }
  }

  [429, headers, [body.to_json]]
end

# Track failed logins
Rack::Attack.track("logins/ip") do |req|
  if req.path == "/api/v1/auth/login" && req.post?
    req.ip
  end
end

# Reset failed logins counter on successful login
Rack::Attack.reset! do |req|
  if req.path == "/api/v1/auth/login" && req.post?
    # TODO: Check if login was successful before resetting
    # This is a simplified version - in production, you'd check the response status
    false
  end
end
