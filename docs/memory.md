# Repository Memory System

This page documents the **Repository Memory System** and the **mandatory read/write flow** every AI agent (Hermes, Claude, Copilot, etc.) must follow when working in `taskflow-api`.

## Why a memory system?

`taskflow-api` is a Rails 7.1 API-only app with JWT auth, Sidekiq, Redis, and PostgreSQL. Its sharp edges — JWT refresh-token rotation, Sidekiq/Redis configuration, rate-limiting (Rack::Attack) tuning, RuboCop style rules, and Testcontainers-free RSpec setup quirks — are exactly the kind of detail that is expensive to rediscover per task. `MEMORY.md` is that living memory.

## Where it lives

- **Memory file:** [`MEMORY.md`](../MEMORY.md) at the repo root.
- **This doc:** `docs/memory.md`.
- **Agent contract:** `AGENTS.md` -> "Repository Memory System".

## The mandatory flow

### 1. READ (before any task)
Open `MEMORY.md` and read it in full before writing code, running a build, or opening a PR. Note the known pitfalls, reuse the verified commands, and honor recorded architecture decisions.

### 2. WRITE (after any task)
After completing a task (especially after fixing a bug, working around a pitfall, making an architecture decision, or validating a command), append to `## Agent Memory Log`:

```
- **YYYY-MM-DD** — `scope`: <one-line summary>.
  - **Learned:** <fact>.
  - **Where:** `<file>` + commit `<sha>` (or branch).
  - **Applies to:** <area/command/component>.
```

Newest entries go **first**.

## Commit policy
`MEMORY.md` must be committed — in its own atomic commit (`docs(memory): ...`) or with the task commit. Never leave it uncommitted.

## Repo quick reference

| Item | Detail |
|------|--------|
| Stack | Rails 7.1 (API); Ruby 3.3; PostgreSQL 15; Redis 7; JWT; Sidekiq; Rack::Attack |
| Build / Run | `bin/rails server` (or `docker compose up --build`) |
| Test | `bundle exec rspec` |
| Deploy | `docker compose up --build` |
| Key files | `app/controllers/api/v1/base_controller.rb`, `app/services/jwt_service.rb`, `app/models/`, `config/routes.rb` |
| Notable | Access tokens expire 15 min; refresh tokens 7 days; validate in `BaseController#authenticate_user!` |

> The canonical, up-to-date version of every item lives in `MEMORY.md`. Treat this page as the explanation; treat `MEMORY.md` as the data.
