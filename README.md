# TaskFlow API

A modern, production-ready RESTful API for task management built with Ruby on Rails 7.1 (API-only mode). Features JWT authentication, background job processing, rate limiting, and Docker support.

## Features

- **RESTful API** — Full CRUD operations for tasks
- **JWT Authentication** — Stateless auth with token refresh
- **Rate Limiting** — Rack::Attack-based request throttling
- **Background Jobs** — Sidekiq-powered async task notifications
- **Caching** — Redis-backed caching layer
- **CI/CD** — GitHub Actions with RuboCop + RSpec
- **Docker** — Multi-stage build with docker-compose orchestration

## Tech Stack

| Component     | Technology        |
|---------------|-------------------|
| Framework     | Rails 7.1 (API)   |
| Language      | Ruby 3.3          |
| Database      | PostgreSQL 15     |
| Cache/Queue   | Redis 7           |
| Auth          | JWT (ruby-jwt)    |
| Background    | Sidekiq           |
| Rate Limiting | Rack::Attack      |
| Testing       | RSpec + FactoryBot|
| Linting       | RuboCop            |

## Prerequisites

- Ruby 3.3+
- PostgreSQL 14+
- Redis 7+
- Docker & Docker Compose (optional)

## Quick Start

### With Docker (recommended)

```bash
git clone https://github.com/igorVilela7713/taskflow-api.git
cd taskflow-api
docker compose up --build
```

The API will be available at `http://localhost:3000`.

### Manual Setup

```bash
git clone https://github.com/igorVilela7713/taskflow-api.git
cd taskflow-api

# Install dependencies
bundle install

# Setup database
bin/rails db:create db:migrate db:seed

# Start Redis (required for Sidekiq)
redis-server

# Start the server
bin/rails server

# Start Sidekiq (in another terminal)
bundle exec sidekiq
```

## API Endpoints

### Authentication

| Method | Endpoint                    | Description         |
|--------|-----------------------------|---------------------|
| POST   | `/api/v1/auth/login`        | Login, get JWT      |
| POST   | `/api/v1/auth/refresh`      | Refresh access token|
| DELETE | `/api/v1/auth/logout`       | Invalidate refresh  |

### Tasks

| Method | Endpoint                | Description        |
|--------|-------------------------|--------------------|
| GET    | `/api/v1/tasks`         | List all tasks     |
| POST   | `/api/v1/tasks`         | Create a task      |
| GET    | `/api/v1/tasks/:id`     | Get a task         |
| PATCH  | `/api/v1/tasks/:id`     | Update a task      |
| DELETE | `/api/v1/tasks/:id`     | Delete a task      |

All task endpoints require a valid JWT token in the `Authorization: Bearer <token>` header.

### Example Request

```bash
# Login
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "user@example.com", "password": "password123"}'

# Create a task (use token from login response)
curl -X POST http://localhost:3000/api/v1/tasks \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"task": {"title": "My Task", "description": "Task details", "priority": "high"}}'
```

## Running Tests

```bash
bundle exec rspec
bundle exec rubocop
```

## License

MIT License. See [LICENSE](LICENSE) for details.
