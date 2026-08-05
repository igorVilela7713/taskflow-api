# PLAN.md — TaskFlow API Implementation Roadmap

## Phase 1: Foundation (Week 1) ✅

### Project Setup
- [x] Initialize Rails 7.1 API-only project
- [x] Configure Gemfile with all dependencies
- [x] Setup Docker + docker-compose
- [x] Configure GitHub Actions CI
- [x] Setup RuboCop, RSpec, FactoryBot

### Database
- [x] Create users migration (email, password_digest, name, refresh_token)
- [x] Create tasks migration (title, description, status, priority, due_date)
- [x] Add indexes for performance
- [x] Setup enums for status and priority

### Core Models
- [x] User model with `has_secure_password`
- [x] Task model with validations and associations
- [x] User has_many :tasks association

---

## Phase 2: Authentication (Week 2)

### JWT Service
- [ ] Implement `JwtService.encode` (access tokens)
- [ ] Implement `JwtService.encode_refresh` (refresh tokens)
- [ ] Implement `JwtService.decode` with validation
- [ ] Add token expiration checks
- [ ] Add secret key management via env vars

### Auth Controller
- [ ] `POST /auth/login` — validate credentials, return tokens
- [ ] `POST /auth/refresh` — validate refresh token, rotate, return new tokens
- [ ] `DELETE /auth/logout` — invalidate refresh token
- [ ] Proper error responses for invalid credentials
- [ ] Handle expired tokens gracefully

### Base Controller
- [ ] `authenticate_user!` before_action
- [ ] `current_user` helper method
- [ ] Global error handling (rescue_from blocks)
- [ ] Standard JSON error response format

---

## Phase 3: Task API (Week 3)

### CRUD Operations
- [ ] `GET /api/v1/tasks` — list tasks with pagination
- [ ] `POST /api/v1/tasks` — create task
- [ ] `GET /api/v1/tasks/:id` — show task
- [ ] `PATCH /api/v1/tasks/:id` — update task
- [ ] `DELETE /api/v1/tasks/:id` — delete task

### Query Features
- [ ] Filter by status (`?status=pending`)
- [ ] Filter by priority (`?priority=high`)
- [ ] Sort by created_at, updated_at, priority, due_date
- [ ] Search by title (`?q=search_term`)
- [ ] Pagination with page/per_page params

### Serializers
- [ ] TaskSerializer (id, title, description, status, priority, due_date, timestamps)
- [ ] UserSerializer (id, email, name, created_at)
- [ ] ErrorSerializer (code, message, details)

---

## Phase 4: Background Jobs (Week 4)

### Sidekiq Setup
- [ ] Configure Sidekiq initializer
- [ ] Setup Redis connection pool
- [ ] Configure queue priorities
- [ ] Add Sidekiq Web UI (admin only)

### Notification Job
- [ ] `TaskNotificationJob` — triggered on task create/update
- [ ] Notification types: email, push, webhook (stubs)
- [ ] Retry logic with exponential backoff
- [ ] Dead letter queue for failed jobs

### Cron Jobs (Future)
- [ ] `TaskCleanupJob` — archive old completed tasks
- [ ] `DailySummaryJob` — send daily task summary
- [ ] Setup sidekiq-cron gem

---

## Phase 5: Rate Limiting & Caching (Week 5)

### Rack::Attack
- [ ] Throttle login attempts (5 per 30s per IP)
- [ ] Throttle API requests (100 per minute)
- [ ] Throttle authenticated requests (300 per 5min per user)
- [ ] Throttle task creation (20 per minute)
- [ ] Custom response with `Retry-After` header

### Caching
- [ ] Configure Redis cache store
- [ ] Cache task list queries (5 min TTL)
- [ ] Cache individual task reads (5 min TTL)
- [ ] Cache invalidation on write operations
- [ ] Cache key strategy: `user:{id}:tasks:{filters_hash}`

---

## Phase 6: Testing & Quality (Week 6)

### Request Specs
- [ ] Auth controller specs (login, refresh, logout)
- [ ] Task controller specs (full CRUD + error cases)
- [ ] Pagination specs
- [ ] Filtering and sorting specs
- [ ] Error response format specs

### Model Specs
- [ ] User model validations
- [ ] Task model validations
- [ ] Association tests
- [ ] Scope tests

### Integration Tests
- [ ] Full auth flow (login → create task → refresh → logout)
- [ ] Rate limiting behavior
- [ ] Background job enqueueing

### Code Quality
- [ ] Achieve 90%+ test coverage
- [ ] Fix all RuboCop offenses
- [ ] Add simplecov for coverage reporting

---

## Phase 7: Production Readiness (Week 7)

### Security
- [ ] Add CORS configuration (rack-cors)
- [ ] Add request ID tracking
- [ ] Add audit logging for sensitive operations
- [ ] Add input sanitization
- [ ] Add SQL injection protection (already via AR)

### Monitoring
- [ ] Add health check endpoint (`GET /health`)
- [ ] Add request logging middleware
- [ ] Add error tracking (Sentry or similar)
- [ ] Add performance monitoring

### Documentation
- [ ] Complete OpenAPI/Swagger spec
- [ ] Add API changelog
- [ ] Update README with production deployment guide
- [ ] Add contributing guidelines

### Deployment
- [ ] Docker production configuration
- [ ] Environment variable documentation
- [ ] Database backup strategy
- [ ] Scaling guide (horizontal + vertical)

---

## Phase 8: Advanced Features (Future)

### Planned Enhancements
- [ ] Task dependencies (prerequisite tasks)
- [ ] Task labels/tags
- [ ] Task attachments (S3 storage)
- [ ] Task comments
- [ ] Task sharing/collaboration
- [ ] Webhooks for external integrations
- [ ] Bulk operations (bulk update, bulk delete)
- [ ] Export tasks (CSV, JSON)
- [ ] Recurring tasks
- [ ] Task templates

### Performance
- [ ] Database query optimization (N+1 prevention)
- [ ] Pagination optimization (cursor-based)
- [ ] GraphQL endpoint (alternative to REST)
- [ ] WebSocket for real-time updates

---

## Milestones

| Milestone | Target Date | Status |
|-----------|-------------|--------|
| Foundation complete | Week 1 | ✅ Done |
| Auth working | Week 2 | 🔲 Pending |
| Tasks CRUD | Week 3 | 🔲 Pending |
| Background jobs | Week 4 | 🔲 Pending |
| Rate limiting | Week 5 | 🔲 Pending |
| Test suite | Week 6 | 🔲 Pending |
| Production ready | Week 7 | 🔲 Pending |
| v1.0 release | Week 8 | 🔲 Pending |
