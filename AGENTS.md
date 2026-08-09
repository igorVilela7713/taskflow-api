# AGENTS.md — AI Agent Instructions for TaskFlow API

This document guides AI agents (Claude, Copilot, Hermes, etc.) working on the TaskFlow API codebase.

## Project Context

TaskFlow API is a Ruby on Rails 7.1 API-only application for task management. It uses JWT authentication, Sidekiq for background jobs, Redis for caching, and PostgreSQL for data storage.

## Architecture

```
taskflow-api/
├── app/
│   ├── controllers/api/v1/   # API controllers (namespaced)
│   ├── models/               # ActiveRecord models
│   ├── serializers/          # JSON serializers (custom, not jbuilder)
│   ├── services/             # Service objects (JWT, etc.)
│   └── jobs/                 # Sidekiq background jobs
├── config/
│   ├── initializers/         # Redis, Sidekiq, Rack::Attack config
│   └── routes.rb             # Versioned API routes
├── db/migrate/               # Database migrations
├── spec/                     # RSpec test suite
└── docker/                   # Docker configuration
```

## Coding Conventions

### Ruby Style
- Follow the RuboCop config in `.rubocop.yml`
- Max line length: 120 characters
- Prefer single quotes for strings (double quotes for interpolation)
- Use keyword arguments for methods with 2+ parameters
- Keep methods under 15 lines
- No trailing commas in multi-line hashes/arrays

### Rails Conventions
- All controllers under `Api::V1` namespace
- Use strong parameters in all controllers
- Return JSON responses (never render HTML)
- Use status codes correctly: 201 for create, 204 for delete, 422 for validation errors
- Model validations should be thorough (presence, uniqueness, inclusion, length)

### API Design
- All endpoints prefixed with `/api/v1/`
- Use consistent JSON response format
- Paginate list endpoints (max 100 per page)
- Include `meta` object with pagination info
- Error responses follow the format in SPEC.md

### Authentication
- JWT tokens generated via `JwtService`
- Access tokens expire in 15 minutes
- Refresh tokens expire in 7 days
- Always validate tokens in `BaseController#authenticate_user!`
- Never store passwords in plain text (use `has_secure_password`)

### Testing
- RSpec for all tests
- FactoryBot for test data
- Request specs for API endpoints
- One spec file per controller
- Test all CRUD operations + error cases
- Use `describe` blocks for each endpoint, `context` for scenarios

### Database
- Migrations go in `db/migrate/` with timestamp prefix
- Add indexes for foreign keys and commonly queried columns
- Use enums for status and priority fields
- Always add `null: false` with default values where appropriate

## Key Files

| File | Purpose |
|------|---------|
| `app/controllers/api/v1/base_controller.rb` | Auth + error handling for all controllers |
| `app/services/jwt_service.rb` | JWT encode/decode logic |
| `config/initializers/rack_attack.rb` | Rate limiting rules |
| `config/initializers/sidekiq.rb` | Background job configuration |
| `Gemfile` | All dependencies |

## Common Tasks

### Adding a new endpoint
1. Add route in `config/routes.rb`
2. Create or update controller in `app/controllers/api/v1/`
3. Add serializer if needed in `app/serializers/`
4. Write request spec in `spec/requests/api/v1/`
5. Update SPEC.md endpoint table

### Adding a new model
1. Create migration in `db/migrate/`
2. Create model in `app/models/` with validations
3. Add associations, scopes, and methods
4. Add factory in `spec/factories/`
5. Write model specs in `spec/models/`

### Modifying authentication
1. Update `JwtService` for token changes
2. Update `BaseController#authenticate_user!` for auth logic
3. Update auth controller for login/refresh/logout
4. Update rate limiting if auth patterns change

## Do NOT

- Do not add frontend code (this is API-only)
- Do not use session-based auth (JWT only)
- Do not add unnecessary gems (keep dependencies minimal)
- Do not commit secrets or environment variables
- Do not skip error handling in controllers
- Do not use `puts` or `print` for logging (use Rails.logger)

## Environment Variables

```bash
DATABASE_URL=postgres://user:pass@localhost:5432/taskflow_api_development
REDIS_URL=redis://localhost:6379/0
JWT_SECRET_KEY=your-secret-key-here
JWT_EXPIRATION=900          # 15 minutes in seconds
REFRESH_EXPIRATION=604800   # 7 days in seconds
```



---

## Repository Memory System (Mandatory Read/Write Flow)

This repository keeps a **living memory** in `MEMORY.md` at the repo root. The file accumulates context across agent sessions — local conventions, known pitfalls, architecture decisions, verified commands and lessons learned — so nothing is rediscovered twice and every agent starts informed.

### Mandatory flow

**1. READ — required at the start of every task**
- Before writing code, running commands, or proposing changes, **read `MEMORY.md` in full**.
- Absorb: known gotchas, build/test conventions, recorded architecture decisions (ADRs), and tool versions.
- If `MEMORY.md` does not exist yet, create the base sections before acting.

**2. WRITE — required at the end of every task**
- After completing any task — especially after fixing a bug, working around a pitfall, making an architecture decision, validating a command, or learning a new gotcha — **update `MEMORY.md`**.
- Append a new entry to `## Agent Memory Log` with: date, agent/author, what was learned, and references (file + commit).
- Commit `MEMORY.md` in an atomic commit (`docs(memory): ...`) or together with the task commit — **never leave it uncommitted**.
- Keep entries short and linkable to source files/commits.

### `MEMORY.md` structure

The file is organized into fixed, scannable sections. The `## Agent Memory Log` section is append-only (newest entry first):

- `# MEMORY.md — Living Memory of the Repo`
- `## Project Summary`
- `## Stack`
- `## Conventions (quick reference)`
- `## Verified Commands (build / test / deploy)`
- `## Known Pitfalls (gotchas)`
- `## Architecture Decisions (ADRs)`
- `## Lessons Learned`
- `## Agent Memory Log`

See [`docs/memory.md`](docs/memory.md) and [`README.md`](README.md) for the full rationale.
