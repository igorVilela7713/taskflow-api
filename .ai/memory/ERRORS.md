# TaskFlow API — Known Errors, Bugs, and Pitfalls

## Git History

Single commit on main branch:
```
eb9d0d0 (HEAD -> main, origin/main) feat: initial project scaffold with Rails API, Docker, and CI
```

---

## TODO / FIXME Comments

### app/jobs/task_notification_job.rb:15
```ruby
# TODO: Implement actual notification logic
# - Send email notification
# - Send push notification
# - Send webhook to external services
```
**Impact:** All notification methods are stubs that only log to Rails.logger. No actual notifications are sent.

### app/jobs/task_notification_job.rb:39
```ruby
# TODO: Send "task created" notification
```
**Impact:** `notify_task_created` method only logs. No email/push/webhook sent on task creation.

### app/jobs/task_notification_job.rb:44
```ruby
# TODO: Send "task updated" notification
```
**Impact:** `notify_task_updated` method only logs. No notification sent on task update.

### app/jobs/task_notification_job.rb:49
```ruby
# TODO: Send "status changed" notification
```
**Impact:** `notify_status_changed` method only logs. No notification sent on status change.

### config/initializers/rack_attack.rb:82
```ruby
# TODO: Check if login was successful before resetting
# This is a simplified version - in production, you'd check the response status
```
**Impact:** `Rack::Attack.reset!` always returns `false` — failed login counter is never reset on successful login. This means the 5-attempt limit per 30s may block legitimate users after repeated failures, even if they eventually succeed.

---

## Known Limitations

### Background Job Notification Logic Not Implemented
- `TaskNotificationJob` (app/jobs/task_notification_job.rb) is enqueued on task create/update
- All three notification methods (`notify_task_created`, `notify_task_updated`, `notify_status_changed`) are stubs
- Only logs to `Rails.logger.info` — no actual email, push, or webhook delivery
- No email service (e.g., SendGrid, Mailgun) is configured
- No push notification service configured
- No webhook delivery mechanism

### Missing Scheduled Jobs
- `TaskCleanupJob` — planned per SPEC.md (archive completed tasks > 90 days) but not implemented
- `DailySummaryJob` — planned per SPEC.md (send daily task summary) but not implemented
- `sidekiq-cron` gem not in Gemfile — no scheduled job infrastructure exists
- No cron configuration in docker-compose.yml or anywhere else

### No Caching in Controllers
- Redis cache store is configured in `config/initializers/redis.rb` and `config/application.rb`
- Cache key pattern and invalidation strategy documented in SPEC.md
- **But:** No `Rails.cache.read/write/delete` calls exist in any controller
- `TasksController#index` queries database on every request — no cache layer
- This is planned for Phase 5 but not yet implemented

### No Cursor-Based Pagination
- Current implementation uses offset-based pagination (`offset` + `limit` in SQL)
- Works well for small datasets but degrades with large page numbers
- Cursor-based pagination planned for Phase 8 (performance optimization)

### No Error Tracking Service
- No Sentry, Honeybadger, or Bugsnag integration
- `rescue_from StandardError` in BaseController renders generic 500 error
- Exception details logged to Rails.logger but not captured in external service
- No stack traces or error grouping available in production

### No Request ID Tracking
- No unique request ID in logs for debugging
- No `X-Request-Id` header in responses
- Makes it hard to trace issues across multiple log entries
- Planned for Phase 7

### No Audit Logging
- No logging of sensitive operations (user login, token refresh, task creation)
- No audit trail for compliance or debugging
- `Rack::Attack.track("logins/ip")` exists but only tracks IP for rate limiting, not for audit
- Planned for Phase 7

### No Production Deployment Guide
- README.md has Docker quickstart but no production deployment instructions
- No environment variable documentation for production
- No database backup strategy
- No scaling guide (horizontal/vertical)
- Planned for Phase 7

### No OpenAPI/Swagger Spec
- API documentation exists only in SPEC.md (human-readable, not machine-readable)
- No OpenAPI 3.0 or Swagger spec for client generation
- Planned for Phase 7

### No Bulk Operations
- Each task must be created/updated/deleted individually via API
- No batch endpoints (e.g., `PATCH /tasks/batch` with array of updates)
- No bulk delete endpoint
- Planned for Phase 8

### Missing Feature Scope
- No task dependencies (prerequisite tasks)
- No task labels/tags
- No task attachments (S3 storage)
- No task comments
- No task sharing/collaboration
- No webhooks for external integrations
- No export (CSV, JSON)
- No recurring tasks
- No task templates
- All planned for Phase 8

---

## Error Handling Details

### RescueFrom Blocks in BaseController (app/controllers/api/v1/base_controller.rb)

```ruby
rescue_from ActiveRecord::RecordNotFound, with: :not_found
rescue_from ActiveRecord::RecordInvalid, with: :unprocessable_entity
rescue_from ActionController::ParameterMissing, with: :bad_request
rescue_from JWT::DecodeError, with: :unauthorized
rescue_from JWT::ExpiredSignature, with: :token_expired
```

| Exception                     | Handler Method        | HTTP Status | Error Code           | Notes                              |
|-------------------------------|-----------------------|-------------|----------------------|------------------------------------|
| ActiveRecord::RecordNotFound  | `not_found`           | 404         | NOT_FOUND            | Returns `exception.message`        |
| ActiveRecord::RecordInvalid   | `unprocessable_entity`| 422         | UNPROCESSABLE_ENTITY | Returns `record.errors.messages`   |
| ActionController::ParameterMissing | `bad_request`    | 400         | BAD_REQUEST          | Returns `exception.message`        |
| JWT::DecodeError              | `unauthorized`        | 401         | UNAUTHORIZED         | Returns `exception.message` or fallback |
| JWT::ExpiredSignature         | `token_expired`       | 401         | TOKEN_EXPIRED        | Returns "Access token has expired. Please refresh." |
| StandardError                 | (not defined)         | 500         | (generic)            | No global handler — will bubble up |

**Note:** There is NO `rescue_from StandardError` handler in BaseController. Unhandled exceptions will return Rails default 500 error page in development or generic error in production.

### AuthController Error Handling (app/controllers/api/v1/auth_controller.rb)

- `AuthController` inherits from `ActionController::API` (NOT `BaseController`)
- Has its own rescue blocks in `refresh` and `logout` methods:
  ```ruby
  rescue JWT::DecodeError, JWT::ExpiredSignature
    render json: { error: { code: "UNAUTHORIZED", message: "Invalid or expired refresh token" } }, status: :unauthorized
  end
  ```
- `login` method has no explicit error handling — relies on `find_by` returning nil and `authenticate` returning false
- `logout` gracefully handles expired tokens — returns success even if JWT decode fails

---

## JWT Token Issues

### Secret Key Management
```ruby
# app/services/jwt_service.rb:5
SECRET_KEY = ENV.fetch("JWT_SECRET_KEY", Rails.application.secret_key_base)
```
- Uses `ENV.fetch` with fallback to `Rails.application.secret_key_base`
- **Risk:** If `JWT_SECRET_KEY` is not set, tokens are signed with the Rails secret key, which may be rotated independently
- **Recommendation:** Always set `JWT_SECRET_KEY` explicitly in production

### Refresh Token Verification
```ruby
# app/controllers/api/v1/auth_controller.rb:51
if user.refresh_token != refresh_token
```
- Refresh tokens are verified by comparing with stored value in `users.refresh_token`
- **Security:** This means refresh tokens are single-use (rotation on each refresh)
- **Edge case:** If a refresh token is used twice (e.g., race condition), the second use will fail with "Invalid refresh token"
- **No revocation list:** Expired refresh tokens are not tracked — they simply fail verification

### Logout Graceful Degradation
```ruby
# app/controllers/api/v1/auth_controller.rb:92-94
rescue JWT::DecodeError, JWT::ExpiredSignature
  render json: { message: "Logged out successfully" }
end
```
- Even if the access token is expired or invalid, logout returns success
- This is intentional — logout should always succeed from the user's perspective
- **Trade-off:** Cannot track failed logout attempts (expired token + logout = silent success)

---

## Rate Limiting Edge Cases

### Unauthenticated vs Authenticated Throttling
- Unauthenticated requests: rate limited by IP address
- Authenticated requests: rate limited by user ID extracted from JWT
- **Edge case:** If JWT decode fails in the authenticated throttle, the request falls back to IP-based throttling (returns `nil` from the lambda, which Rack::Attack ignores)

### Login Reset Counter Bug
```ruby
# config/initializers/rack_attack.rb:80-86
Rack::Attack.reset! do |req|
  if req.path == "/api/v1/auth/login" && req.post?
    # TODO: Check if login was successful before resetting
    false  # Always returns false — counter never resets
  end
end
```
- The `reset!` block always returns `false`, so the login attempt counter is never reset
- After 5 failed attempts in 30s, the IP is blocked for the full 30s window even if the user eventually enters correct credentials
- **Fix needed:** Should check response status (200 = successful login) before resetting

### Task Creation Throttle Key
```ruby
# config/initializers/rack_attack.rb:41
"user:#{decoded.first['user_id']}"
```
- Authenticated task creation uses `user:N` as the throttle key
- Unauthenticated falls back to `req.ip`
- **Note:** This means a user can make 20 task creations per minute, regardless of how many IPs they use

---

## Cache Invalidation Notes

### delete_matched Pattern
```ruby
Rails.cache.delete_matched("user:#{user_id}:tasks:*")
```
- Uses Redis `KEYS` command under the hood (expensive on large datasets)
- **Performance risk:** If the `taskflow_cache` namespace has many keys, `delete_matched` can be slow
- **Alternative:** Use explicit cache keys with timestamps (not implemented)

### Cache Not Actually Used
- Cache invalidation code is documented in SPEC.md but not implemented in controllers
- `TasksController#index` has no `Rails.cache.fetch` calls
- Redis cache store is configured but unused — all queries hit the database

---

## Database Schema Notes

### Migration Naming
- Migrations use simple numeric prefixes: `001_create_users.rb`, `002_create_tasks.rb`
- Schema version: `2024_01_01_000002` (not standard Rails timestamp format)
- **Note:** This is non-standard — Rails typically uses `YYYYMMDDHHMMSS` format
- Works fine but may cause confusion if migrations are added later

### Enum Default Values
```ruby
# db/migrate/002_create_tasks.rb:9-10
t.integer :status, null: false, default: 0   # pending
t.integer :priority, null: false, default: 1  # medium
```
- Status default: 0 (pending)
- Priority default: 1 (medium)
- **Gotcha:** If you insert a task without specifying status/priority, it gets pending/medium
- Model enums must match migration defaults exactly

### Due Date Validation
```ruby
# app/models/task.rb:14
validates :due_date, comparison: { greater_than: -> { Date.current } }, allow_nil: true
```
- Due date must be in the future (greater than today)
- `allow_nil: true` — tasks can exist without due dates
- **Edge case:** Setting due_date to today will fail validation (must be strictly greater than)

---

## Testing Gaps

### No Auth Controller Specs
- `spec/requests/api/v1/tasks_spec.rb` exists with comprehensive task endpoint tests
- **Missing:** No spec file for `AuthController` (login, refresh, logout)
- Auth endpoints are untested — potential for silent regressions

### No Model Specs
- No `spec/models/user_spec.rb` or `spec/models/task_spec.rb`
- Model validations, scopes, and callbacks are untested
- `shoulda-matchers` is configured but not used

### No Job Specs
- No specs for `TaskNotificationJob`
- Background job behavior is untested

### No Service Specs
- No specs for `JwtService`
- Token encode/decode logic is untested

### Task Spec Missing Delete Return Status
```ruby
# spec/requests/api/v1/tasks_spec.rb:152
expect(response).to have_http_status(:ok)
```
- `TasksController#destroy` returns status `:ok` (200)
- **SPEC.md says:** DELETE should return 204 No Content
- **Discrepancy:** Code returns 200 with `{ message: "Task deleted successfully" }`, spec expects 200
- Either the code or the spec needs to change

---

## Environment-Specific Issues

### Development Caching Disabled
```ruby
# config/environments/development.rb:19-22
if Rails.env.development?
  config.action_controller.perform_caching = false
  config.cache_store = :null_store
end
```
- Caching is disabled in development (null_store)
- Redis cache configuration is overridden
- **Impact:** Cache-related code cannot be tested in development — must use test or production env

### CI Environment
```yaml
# .github/workflows/ci.yml
env:
  DATABASE_URL: postgres://taskflow:***@localhost:5432/taskflow_api_test
  REDIS_URL: redis://localhost:6379/0
  JWT_SECRET_KEY: test_secret_key_for_ci
```
- CI uses hardcoded JWT secret (not secure, but acceptable for tests)
- PostgreSQL and Redis services run as Docker containers in CI
- Coverage reports uploaded as artifacts (retention: 7 days)

---

## CORS Configuration Warning

```ruby
# config/initializers/cors.rb:8
origins "*"
```
- CORS allows ALL origins — insecure for production
- **Risk:** Any website can make authenticated requests to the API
- **Fix needed:** Restrict origins to specific domains in production
- Should also restrict `methods` and `headers` in production
