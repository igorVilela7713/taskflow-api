# TaskFlow API — Architectural Decision Records (ADR)

## ADR-001: Rails 7.1 API-Only Mode

**Status:** Accepted

**Context:** TaskFlow API is a backend service for task management. There is no frontend code in this repository — clients are expected to be mobile apps, SPAs, or other services.

**Decision:** Use Rails 7.1 in API-only mode (`config.api_only = true` in `config/application.rb`). This excludes view layer, asset pipeline, session middleware, cookies, flash, and other browser-oriented features.

**Consequences:**
- Smaller memory footprint and faster boot times
- All controllers inherit from `ActionController::API` (not `ApplicationController`)
- No HTML rendering — all responses are JSON
- No session-based authentication — JWT-only approach
- Middleware stack is minimal (no ActionDispatch::Session, no ActionDispatch::Cookies)

---

## ADR-002: Ruby 3.3

**Status:** Accepted

**Context:** Ruby 3.3 is the latest stable release with performance improvements (YJIT improvements, M:N thread model) and new language features.

**Decision:** Pin Ruby to 3.3.0 in the Gemfile (`ruby "3.3.0"`) and Dockerfile (`ruby:3.3-slim`).

**Consequences:**
- Access to latest language features (numbered parameters, pattern matching improvements)
- Better YJIT performance for production workloads
- Requires Ruby 3.3+ on developer machines (not backward-compatible with 3.2 or earlier)

---

## ADR-003: PostgreSQL 15 as Primary Database

**Status:** Accepted

**Context:** TaskFlow needs a reliable relational database for structured data (users, tasks) with ACID compliance, complex queries, and indexing support.

**Decision:** Use PostgreSQL 15 via the `pg` gem. Docker setup uses `postgres:15-alpine`.

**Consequences:**
- Full SQL support including ILIKE for title search (used in `TasksController#apply_filters`)
- JSONB support available for future extensions
- pg-specific features (array types, CTEs) available but not yet used
- Indexes defined for: email (unique), refresh_token, user_id, status, priority, composite (user_id, status)

---

## ADR-004: Redis 7 for Cache and Sidekiq Queue

**Status:** Accepted

**Context:** TaskFlow needs both a caching layer (for task list queries) and a job queue backend (for Sidekiq background processing).

**Decision:** Use Redis 7 for both `Rails.cache` (via `redis_cache_store`) and Sidekiq's job queue. Single Redis instance serves both purposes via namespace separation (`taskflow_cache` for cache, default for Sidekiq).

**Consequences:**
- Single infrastructure dependency reduces operational complexity
- Cache namespace `taskflow_cache` avoids key collisions with Sidekiq
- Default cache TTL of 5 minutes configured in `config/initializers/redis.rb`
- Network timeout and pool timeout both set to 5 seconds in Sidekiq config
- Risk: if Redis goes down, both caching and background jobs fail simultaneously

---

## ADR-005: JWT (HS256) for Stateless Authentication

**Status:** Accepted

**Context:** TaskFlow API is consumed by multiple client types (web, mobile, third-party). Session-based auth requires server-side session storage and doesn't work well for API consumers.

**Decision:** Use JWT tokens with HS256 algorithm via the `ruby-jwt` gem. Implemented in `app/services/jwt_service.rb`.

**Consequences:**
- Stateless authentication — no server-side session storage needed
- Tokens are self-contained with `{ user_id, exp, iat }` payload
- Secret key management via `ENV["JWT_SECRET_KEY"]` with fallback to `Rails.application.secret_key_base`
- Access tokens verified with `algorithm: "HS256"` and `verify_expiration: true`
- Trade-off: cannot revoke access tokens before expiry (only refresh tokens can be rotated/invalidated)

---

## ADR-006: Access Token 15min / Refresh Token 7 Days with DB Rotation

**Status:** Accepted

**Context:** Need to balance security (short-lived tokens) with user experience (not requiring frequent re-login). Refresh tokens provide the bridge.

**Decision:**
- Access tokens: 15 minutes (`15.minutes.from_now.to_i`)
- Refresh tokens: 7 days (`7.days.from_now.to_i`), stored in `users.refresh_token` column
- Refresh token rotation: each refresh generates a new refresh token, old one is replaced in DB

**Consequences:**
- Short access tokens limit exposure window if token is compromised
- Refresh token stored in DB allows server-side invalidation (logout sets `refresh_token: nil`)
- Rotation on refresh prevents token reuse attacks
- Trade-off: refresh tokens are single-use (if a refresh token is used twice, the second use fails because DB was already updated)
- Logout returns success even if access token is expired (graceful degradation in `AuthController#logout`)

---

## ADR-007: bcrypt for Password Hashing

**Status:** Accepted

**Context:** User passwords must be stored securely, never in plain text.

**Decision:** Use `bcrypt` gem with `has_secure_password` in the User model.

**Consequences:**
- Passwords stored as `password_digest` (bcrypt hash)
- Authentication via `user.authenticate(params[:password])` in `AuthController#login`
- Password minimum length: 8 characters (only validated on new record or password change)
- `has_secure_password` automatically adds `password` and `password_confirmation` virtual attributes
- bcrypt provides automatic salting and configurable cost factor

---

## ADR-008: Sidekiq for Background Jobs

**Status:** Accepted

**Context:** TaskFlow needs to send notifications asynchronously (email, push, webhook) without blocking API responses.

**Decision:** Use Sidekiq 7.2 with Redis as the queue backend. Configured via `config/initializers/sidekiq.rb`. Rails `active_job.queue_adapter` set to `:sidekiq`.

**Consequences:**
- Jobs are enqueued with `JobClass.perform_async(args)` (Sidekiq native API)
- `TaskNotificationJob` is triggered on task create/update in `TasksController`
- Queue configuration: `queue: :notifications, retry: 3, backtrace: true`
- Trade-off: Sidekiq requires Redis (already used for caching)
- Sidekiq Web UI not yet configured (planned for Phase 4)
- `sidekiq-cron` not set up for scheduled jobs (TaskCleanupJob is planned but not implemented)

---

## ADR-009: Redis-Backed Rails.cache for Caching

**Status:** Accepted

**Context:** Task list queries can be expensive (filtering, sorting, pagination). Caching avoids repeated database queries for the same data.

**Decision:** Use `redis_cache_store` as the Rails cache backend with namespace `taskflow_cache` and default TTL of 5 minutes.

**Consequences:**
- Cache store configured in `config/initializers/redis.rb` and `config/application.rb`
- Pool size: 5, pool timeout: 5 seconds
- Cache invalidation strategy: `Rails.cache.delete_matched("user:#{user_id}:tasks:*")` on write operations
- Cache key pattern: `user:{id}:tasks:{filters_hash}`
- **Note:** Caching is configured but not explicitly used in controllers yet — this is planned for Phase 5

---

## ADR-010: Rack::Attack for Rate Limiting

**Status:** Accepted

**Context:** API endpoints need protection against abuse, brute-force attacks, and excessive usage.

**Decision:** Use Rack::Attack 6.7 for rate limiting with four throttle rules defined in `config/initializers/rack_attack.rb`.

**Consequences:**
- Login attempts: 5 per 30 seconds per IP
- General API: 100 requests per minute per IP
- Authenticated API: 300 requests per 5 minutes per user ID (extracted from JWT)
- Task creation: 20 requests per minute per user ID or IP
- Custom throttle responder returns JSON error with `Retry-After` header
- **Limitation:** Login reset counter always returns false (TODO in code — should check response status)
- Excludes `/assets` and `/health` from general throttling

---

## ADR-011: Offset-Based Pagination

**Status:** Accepted

**Context:** Task listing needs to support large datasets without loading all records at once.

**Decision:** Use offset-based pagination with `page` and `per_page` query parameters. Implemented manually in `TasksController#index` (no gem dependency).

**Consequences:**
- Default page: 1, per_page: 20, max per_page: 100
- Total count calculated via `tasks.count` before offset/limit
- Response includes `meta` object: `{ current_page, per_page, total_count, total_pages }`
- Simple implementation — no gem overhead
- Trade-off: offset-based pagination can be slow for very large datasets with high page numbers (cursor-based planned for Phase 8)

---

## ADR-012: Custom JSON Serializers (Not Jbuilder)

**Status:** Accepted

**Context:** API responses need consistent JSON formatting. Need a serialization layer that's simple and performant.

**Decision:** Use custom serializer classes (plain Ruby) instead of jbuilder or active_model_serializers for response formatting.

**Consequences:**
- `TaskSerializer` at `app/serializers/task_serializer.rb` — simple `as_json` method returning a hash
- `active_model_serializers` gem is included in Gemfile but not actively used
- No template DSL overhead — just Ruby hash construction
- Serializers are not DRY across endpoints (each builds its own hash)
- Easy to understand and modify — no magic

---

## ADR-013: RSpec + FactoryBot for Testing

**Status:** Accepted

**Context:** Need a robust testing framework for API integration tests, model specs, and request specs.

**Decision:** Use RSpec 6.0 with FactoryBot 6.4, shoulda-matchers 5.3, webmock 3.19, and simplecov for coverage.

**Consequences:**
- Request specs for API endpoint testing (primary test type)
- FactoryBot syntax methods included globally via `config.include FactoryBot::Syntax::Methods`
- Transactional fixtures enabled (`use_transactional_fixtures = true`)
- Shoulda Matchers configured for model validation testing
- Specs run in random order with seeded randomization
- SimpleCov for coverage reporting (artifact uploaded in CI)

---

## ADR-014: RuboCop for Linting

**Status:** Accepted

**Context:** Need consistent code style across the codebase and automated code quality checks.

**Decision:** Use RuboCop with `rubocop-rails` and `rubocop-rspec` extensions. Configuration in `.rubocop.yml`.

**Consequences:**
- Target Ruby version: 3.3
- Max line length: 120 (comments exempt)
- Single quotes enforced, double quotes for interpolation only
- No trailing commas in multi-line constructs
- Method length max: 20, AbcSize max: 25, ClassLength max: 150
- Excludes: db/schema.rb, db/migrate/, bin/, node_modules/, vendor/, spec/
- Runs in CI pipeline before RSpec tests

---

## ADR-015: API Versioning via /api/v1/ Namespace

**Status:** Accepted

**Context:** API needs to evolve without breaking existing clients. Versioning provides a migration path.

**Decision:** All endpoints are under `/api/v1/` namespace. Future versions will be `/api/v2/`, etc.

**Consequences:**
- Controllers namespaced: `Api::V1::BaseController`, `Api::V1::TasksController`, `Api::V1::AuthController`
- Routes defined in `config/routes.rb` with `namespace :api { namespace :v1 { ... } }`
- Header-based versioning also supported: `Accept: application/vnd.taskflow.v1+json`
- Content negotiation falls back to URL-based versioning
- Trade-off: URL-based versioning is simpler but less "RESTful" than content negotiation

---

## ADR-016: Strong Parameters in All Controllers

**Status:** Accepted

**Context:** Rails mass assignment protection is critical for security. User input must be explicitly whitelisted.

**Decision:** All controllers use strong parameters via private `*_params` methods. `TasksController` uses `params.require(:task).permit(...)`.

**Consequences:**
- Prevents mass assignment vulnerabilities
- Explicit whitelist of allowed attributes per endpoint
- `TasksController#task_params` permits: title, description, status, priority, due_date
- AuthController uses direct `params[:email]` and `params[:password]` (no model mass assignment)
- Consistent pattern across all controllers

---

## ADR-017: Enums for Status and Priority Fields

**Status:** Accepted

**Context:** Task status and priority have a fixed set of valid values. Need database-level and application-level validation.

**Decision:** Use Rails enum for `status` and `priority` integer columns in the Task model.

**Consequences:**
- Status: pending=0, in_progress=1, completed=2, cancelled=3 (default: pending)
- Priority: low=0, medium=1, high=2, urgent=3 (default: medium)
- Provides scopes: `Task.pending`, `Task.in_progress`, etc.
- Database stores integers (efficient), application uses symbols/strings
- Validates inclusion in enum values (`validates :status, inclusion: { in: statuses.keys }`)
- Indexes on both columns for efficient filtering

---

## ADR-018: Error Response Format {error: {code, message, details}}

**Status:** Accepted

**Context:** API clients need a consistent, parseable error format to handle failures programmatically.

**Decision:** All error responses follow the format: `{ error: { code: "...", message: "...", details: {...} } }`

**Consequences:**
- Error codes are UPPER_SNAKE_CASE strings (NOT_FOUND, UNAUTHORIZED, UNPROCESSABLE_ENTITY, etc.)
- `message` is a human-readable description
- `details` is optional — used for validation errors (field-level error messages)
- Consistent across all controllers (BaseController rescue_from handlers + manual error rendering)
- Rate limit errors include `retry_after` field in addition to standard error format

---

## ADR-019: Frozen String Literals in All Ruby Files

**Status:** Accepted

**Context:** Ruby 2.3+ supports frozen string literals pragma for performance and memory safety.

**Decision:** All Ruby files include `# frozen_string_literal: true` as the first comment line. Enforced by RuboCop (`Style/FrozenStringLiteralComment: Enabled: true`).

**Consequences:**
- Strings are frozen by default — prevents accidental mutation
- Performance benefit: Ruby doesn't need to allocate new memory for string mutations
- Must use `+` or `.dup` for mutable strings when needed
- Applied consistently across all app/, config/, spec/ files

---

## ADR-020: No Frontend Code (API-Only)

**Status:** Accepted

**Context:** TaskFlow API is a backend service. Frontend is handled by separate repositories/apps.

**Decision:** No frontend code in this repository. Explicitly stated in AGENTS.md: "Do not add frontend code (this is API-only)."

**Consequences:**
- CORS configured to allow all origins (`origins "*"`) for frontend consumption
- No asset pipeline, no views, no helpers
- API documentation serves as the interface contract (SPEC.md)
- Clients must implement their own UI using the REST API
- Future: OpenAPI/Swagger spec planned for Phase 7

---

## ADR-021: Docker Multi-Stage Build

**Status:** Accepted

**Context:** Need reproducible deployment artifact with minimal attack surface and fast builds.

**Decision:** Multi-stage Dockerfile with builder and runner stages using `ruby:3.3-slim`.

**Consequences:**
- Builder stage: installs build-essential, libpq-dev, nodejs, npm, git; bundles gems without dev/test
- Runner stage: minimal runtime with libpq5 and curl only
- Non-root user `appuser` for security
- Health check via `curl -f http://localhost:3000/up`
- docker-compose orchestrates 4 services: db, redis, app, sidekiq
- Named volumes for data persistence (postgres_data, redis_data, bundle_cache)
