# MEMORY.md — Living Memory of the Repo

> **Working agreement (mandatory):** read this file before any task and append findings on completion. See `AGENTS.md` -> "Repository Memory System" and `docs/memory.md`.

## Project Summary
A Ruby on Rails 7.1 API-only application for task management. Uses JWT authentication, Sidekiq for background jobs, Redis for caching, and PostgreSQL for data. Includes Rack::Attack rate limiting and Docker support.

## Stack
- Ruby 3.3, Rails 7.1 (API-only)
- PostgreSQL 15, Redis 7
- JWT (ruby-jwt) auth with 15-min access / 7-day refresh tokens
- Sidekiq (background jobs), Rack::Attack (rate limiting)
- RSpec + FactoryBot, RuboCop

## Conventions (quick reference)
- All controllers under `Api::V1` namespace.
- Strong parameters in all controllers; JSON responses only.
- Status codes: 201 create, 204 delete, 422 validation errors.
- Ruby style: 120-char lines, single quotes (double for interpolation), keyword args (2+ params), methods < 15 lines, no trailing commas in multi-line.
- Enums for status/priority; indexes for FKs and commonly queried columns; `null: false` with defaults where appropriate.

## Verified Commands (build / test / deploy)
| Step | Command | Notes |
|------|---------|-------|
| Infra | `docker compose up --build` | full stack |
| Setup | `bundle install` then `bin/rails db:create db:migrate db:seed` | |
| Server | `bin/rails server` | API at http://localhost:3000 |
| Sidekiq | `bundle exec sidekiq` | in another terminal |
| Tests | `bundle exec rspec` | |
| Lint | `bundle exec rubocop` | |

## Notable architecture facts
- Access tokens expire in 15 minutes; refresh tokens in 7 days. Always validate in `BaseController#authenticate_user!`.
- Pagination: list endpoints capped at 100 per page, with a `meta` object.

## Known Pitfalls (gotchas)
_(add entries here as they are discovered)_

## Architecture Decisions (ADRs)
_(add ADR entries here as they are made)_

## Lessons Learned
_(add lessons here)_

## Agent Memory Log
- **2026-08-06** — `memory-system`: Introduced the Repository Memory System. Updated `AGENTS.md`, `README.md` and `docs/memory.md` with the mandatory read/write flow; seeded this file with project facts.
