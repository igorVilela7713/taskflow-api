# TaskFlow API — Project Memory

## Project Overview

TaskFlow API is a Ruby on Rails 7.1 API-only application providing a RESTful interface for task management with JWT authentication, background job processing, rate limiting, and Redis-backed caching.

- **Repository:** https://github.com/igorVilela7713/taskflow-api
- **License:** MIT
- **Current Status:** Phase 1 (Foundation) complete; Phases 2-8 planned per PLAN.md

## Tech Stack

| Component       | Technology              | Version   |
|-----------------|-------------------------|-----------|
| Language        | Ruby                    | 3.3.0     |
| Framework       | Rails                   | 7.1 (API-only) |
| Database        | PostgreSQL              | 15        |
| Cache/Queue     | Redis                   | 7         |
| Auth            | JWT (ruby-jwt)          | 2.7       |
| Password Hash   | bcrypt                  | 3.1       |
| Background Jobs | Sidekiq                 | 7.2       |
| Rate Limiting   | Rack::Attack            | 6.7       |
| Serialization   | active_model_serializers| 0.10      |
| CORS            | rack-cors               | 2.0       |
| Web Server      | Puma                    | 5.0+      |
| Testing         | RSpec + FactoryBot      | 6.0 / 6.4 |
| Linting         | RuboCop + rubocop-rails + rubocop-rspec | latest |
| Coverage        | simplecov               | latest    |
| Mocking         | webmock                 | 3.19      |
| Matchers        | shoulda-matchers        | 5.3       |
| Fake Data       | faker                   | 3.2       |

## Architecture

Rails API-only MVC with versioned namespace:

```
taskflow-api/
├── app/
│   ├── controllers/api/v1/   # API controllers (namespaced)
│   │   ├── base_controller.rb   # Auth + error handling for all controllers
│   │   ├── auth_controller.rb   # Login, refresh, logout (standalone, no BaseController)
│   │   └── tasks_controller.rb  # CRUD + filtering + sorting + pagination
│   ├── models/
│   │   ├── user.rb             # has_secure_password, email/name/password_digest/refresh_token
│   │   └── task.rb             # title/description/status/priority/due_date with enums
│   ├── serializers/
│   │   └── task_serializer.rb  # Custom JSON serializer (not jbuilder)
│   ├── services/
│   │   └── jwt_service.rb      # JWT encode/decode with HS256
│   └── jobs/
│       └── task_notification_job.rb  # Sidekiq job (stubs only, not implemented)
├── config/
│   ├── initializers/
│   │   ├── rack_attack.rb      # Rate limiting rules
│   │   ├── sidekiq.rb          # Redis connection config
│   │   ├── redis.rb            # Redis + Rails.cache config
│   │   └── cors.rb             # CORS (origins: *)
│   ├── routes.rb               # Versioned API routes under /api/v1
│   └── application.rb          # API-only mode, cache store, Sidekiq adapter
├── db/
│   ├── migrate/
│   │   ├── 001_create_users.rb
│   │   └── 002_create_tasks.rb
│   └── schema.rb               # Schema version: 2024_01_01_000002
├── spec/
│   ├── requests/api/v1/tasks_spec.rb
│   ├── factories/users.rb, tasks.rb
│   ├── rails_helper.rb         # Shoulda Matchers, FactoryBot, transactional fixtures
│   └── spec_helper.rb
├── .github/workflows/ci.yml   # GitHub Actions: RuboCop + RSpec
├── Dockerfile                  # Multi-stage build (ruby:3.3-slim)
├── docker-compose.yml          # db (postgres:15-alpine), redis (redis:7-alpine), app, sidekiq
└── Gemfile                     # All dependencies
```

## Environment Requirements

- Ruby 3.3+
- PostgreSQL 14+
- Redis 7+
- Docker & Docker Compose (optional, for local development)

## Build / Test / Run Commands

```bash
# Docker (recommended)
docker compose up --build

# Manual setup
bundle install
bin/rails db:create db:migrate db:seed
redis-server          # in one terminal
bin/rails server      # in another terminal
bundle exec sidekiq   # in another terminal

# Testing
bundle exec rspec
bundle exec rubocop
```

## API Endpoints

All endpoints are under `/api/v1`.

### Authentication (no auth required)
| Method | Path                | Description                          | Status |
|--------|---------------------|--------------------------------------|--------|
| POST   | /api/v1/auth/login  | Login, get access + refresh tokens   | 200    |
| POST   | /api/v1/auth/refresh| Refresh access token (rotation)      | 200    |
| DELETE | /api/v1/auth/logout | Invalidate refresh token             | 200    |

### Tasks (auth required)
| Method | Path                  | Description                          | Status |
|--------|-----------------------|--------------------------------------|--------|
| GET    | /api/v1/tasks         | List tasks (paginated, filtered)     | 200    |
| POST   | /api/v1/tasks         | Create a task                        | 201    |
| GET    | /api/v1/tasks/:id     | Get a task                           | 200    |
| PATCH  | /api/v1/tasks/:id     | Update a task                        | 200    |
| DELETE | /api/v1/tasks/:id     | Delete a task                        | 200    |

### Query Parameters (GET /api/v1/tasks)
- `page` (default: 1)
- `per_page` (default: 20, max: 100)
- `status` (pending, in_progress, completed, cancelled)
- `priority` (low, medium, high, urgent)
- `q` (title search, ILIKE)
- `due_after` / `due_before` (date range)
- `sort` (created_at, updated_at, priority, due_date, title; default: created_at)
- `order` (asc, desc; default: desc)

### Health Check
- `GET /up` — Rails built-in health check

## Authentication Flow

### JWT Token Strategy
- **Algorithm:** HS256 (JwtService class at `app/services/jwt_service.rb`)
- **Secret:** `ENV["JWT_SECRET_KEY"]` with fallback to `Rails.application.secret_key_base`
- **Access Token:** 15 minutes, payload: `{ user_id, exp, iat }`
- **Refresh Token:** 7 days, payload: `{ user_id, exp, iat, type: "refresh" }`, stored in `users.refresh_token`

### Login Flow
1. Client sends `{ email, password }` to `POST /auth/login`
2. `User.find_by(email: ...)` + `bcrypt` authenticate
3. `JwtService.encode` creates access token (15min)
4. `JwtService.encode_refresh` creates refresh token (7 days)
5. Refresh token saved to `users.refresh_token`
6. Returns `{ access_token, refresh_token, user: { id, email, name } }`

### Refresh Flow
1. Client sends `{ refresh_token }` to `POST /auth/refresh`
2. `JwtService.decode` validates token (expiration + signature)
3. `User.find(decoded[:user_id])` retrieves user
4. Verifies `user.refresh_token == refresh_token` (rotation check)
5. Generates new access + refresh tokens
6. Saves new refresh token to DB
7. Returns `{ access_token, refresh_token }`

### Logout Flow
1. Client sends request with access token in Authorization header
2. Decodes token, finds user, sets `refresh_token: nil`
3. Returns `{ message: "Logged out successfully" }`
4. **Graceful degradation:** If token is expired, still returns success

## Models

### User (`app/models/user.rb`)
- `has_secure_password` (bcrypt)
- `has_many :tasks, dependent: :destroy`
- Fields: email (unique, indexed), password_digest, name, refresh_token (indexed)
- Validations: email (presence, uniqueness case-insensitive, format), name (presence, max 100), password (min 8, only on new record or password change)
- Callbacks: `before_save :downcase_email`

### Task (`app/models/task.rb`)
- `belongs_to :user`
- Fields: title (max 255), description (text), status (enum), priority (enum), due_date (date), completed_at (datetime)
- Enums:
  - `status`: pending=0, in_progress=1, completed=2, cancelled=3 (default: pending)
  - `priority`: low=0, medium=1, high=2, urgent=3 (default: medium)
- Scopes:
  - `active` — not completed/cancelled
  - `by_priority(priority)` — filter by priority
  - `overdue` — due_date < today and not completed
  - `due_soon(days=3)` — due within N days and not completed
- Callbacks: `after_save :set_completed_at` (sets completed_at when status changes to completed)

## Caching Strategy

- **Backend:** Redis via `Rails.cache` (redis_cache_store)
- **Configuration:** `config/initializers/redis.rb` — namespace `taskflow_cache`, TTL 5 minutes, pool_size 5
- **Cache keys:** `user:{id}:tasks:{filters_hash}` pattern
- **Invalidation:** `Rails.cache.delete_matched("user:#{user_id}:tasks:*")` on task create/update/delete
- **Note:** Caching is configured but not explicitly used in controllers yet (Phase 5 planned)

## Background Jobs

### TaskNotificationJob (`app/jobs/task_notification_job.rb`)
- Queue: `notifications`
- Retry: 3 attempts, backtrace enabled
- Triggered on task create (action: "created") and update (action: "updated")
- **Implementation status:** STUBS ONLY — logs to Rails.logger, no actual notification logic
- Private methods: `notify_task_created`, `notify_task_updated`, `notify_status_changed`

### Planned Jobs (not implemented)
- `TaskCleanupJob` — archive completed tasks > 90 days (daily cron via sidekiq-cron)
- `DailySummaryJob` — send daily task summary

## Rate Limiting (Rack::Attack)

Defined in `config/initializers/rack_attack.rb`:

| Throttle Name              | Limit    | Window     | Key By        |
|----------------------------|----------|------------|---------------|
| requests/ip                | 100      | 1 minute   | IP            |
| logins/ip                  | 5        | 30 seconds | IP            |
| authenticated_requests     | 300      | 5 minutes  | user_id (JWT) |
| task_creation              | 20       | 1 minute   | user_id or IP |

- Unauthenticated: rate limited by IP address
- Authenticated: rate limited by user ID extracted from JWT
- Custom response includes `Retry-After` header and JSON error body
- **Note:** Login reset counter always returns false (TODO: check response status)

## Error Handling

### Global Exception Handling (BaseController)
| Exception                     | HTTP Status | Error Code           |
|-------------------------------|-------------|----------------------|
| ActiveRecord::RecordNotFound  | 404         | NOT_FOUND            |
| ActiveRecord::RecordInvalid   | 422         | UNPROCESSABLE_ENTITY |
| ActionController::ParameterMissing | 400  | BAD_REQUEST          |
| JWT::DecodeError              | 401         | UNAUTHORIZED         |
| JWT::ExpiredSignature         | 401         | TOKEN_EXPIRED        |
| StandardError                 | 500         | INTERNAL_SERVER_ERROR|

### Standard Error Response Format
```json
{
  "error": {
    "code": "UNPROCESSABLE_ENTITY",
    "message": "Validation failed",
    "details": { "title": ["can't be blank"] }
  }
}
```

### HTTP Status Codes Used
200 (success), 201 (created), 400 (bad request), 401 (unauthorized), 404 (not found), 422 (unprocessable entity), 429 (rate limited), 500 (server error)

## Pagination

Offset-based pagination (implemented in `TasksController#index`):
- Default page: 1, per_page: 20, max per_page: 100
- Response includes `meta` object: `{ current_page, per_page, total_count, total_pages }`

## Coding Conventions

From `.rubocop.yml` and AGENTS.md:
- Max line length: 120 characters (comments exempt)
- Single quotes for strings, double quotes for interpolation
- `frozen_string_literal: true` in all Ruby files
- Method length max: 20 lines (RuboCop), < 15 lines preferred (AGENTS.md)
- AbcSize max: 25, ClassLength max: 150, ModuleLength max: 200
- No trailing commas in multi-line arrays/hashes/arguments
- Ruby19 hash syntax (`key: value`)
- Strong parameters in all controllers
- All controllers under `Api::V1` namespace
- JSON responses only (never HTML)
- Correct HTTP status codes (201 create, 204 delete, 422 validation errors)

## Environment Variables

| Variable           | Default/Example                                           | Description            |
|--------------------|-----------------------------------------------------------|------------------------|
| DATABASE_URL       | postgres://taskflow:***@localhost:5432/taskflow_api_development | PostgreSQL connection |
| REDIS_URL          | redis://localhost:6379/0                                   | Redis connection       |
| JWT_SECRET_KEY     | (required) Falls back to Rails.secret_key_base            | JWT signing secret     |
| JWT_EXPIRATION     | 900 (15 minutes in seconds)                               | Access token TTL       |
| REFRESH_EXPIRATION | 604800 (7 days in seconds)                                | Refresh token TTL      |
| RAILS_ENV          | development / test / production                            | Rails environment      |
| RAILS_MASTER_KEY   | (from config/master.key)                                   | Rails master key       |

## Docker Configuration

### Multi-stage Build (Dockerfile)
- **Builder stage:** `ruby:3.3-slim`, installs build-essential + libpq-dev + nodejs + npm + git
- **Runner stage:** `ruby:3.3-slim`, installs libpq5 + curl, creates non-root `appuser`
- Health check: `curl -f http://localhost:3000/up`
- Exposes port 3000

### docker-compose.yml Services
- `db`: postgres:15-alpine (port 5432, volume: postgres_data)
- `redis`: redis:7-alpine (port 6379, volume: redis_data)
- `app`: Rails API (port 3000, depends on db + redis)
- `sidekiq`: Same image, runs `bundle exec sidekiq`
- Named volumes: postgres_data, redis_data, bundle_cache

## Testing Setup

- **Framework:** RSpec 6.0 with FactoryBot 6.4
- **Type:** Request specs (API integration tests)
- **Factories:** `spec/factories/users.rb` (sequence email, Faker name), `spec/factories/tasks.rb` (Faker title/description, default pending/medium)
- **Config:** Transactional fixtures, random order, FactoryBot syntax methods, Shoulda Matchers
- **CI:** GitHub Actions — RuboCop + RSpec with PostgreSQL 15 + Redis 7 services
- **Coverage:** simplecov (artifact uploaded in CI)

## Git History

Single commit on main branch:
- `eb9d0d0` — `feat: initial project scaffold with Rails API, Docker, and CI`
