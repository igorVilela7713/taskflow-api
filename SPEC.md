# TaskFlow API — Architecture Specification

## Overview

TaskFlow API is a Rails 7.1 API-only application providing a RESTful interface for task management with JWT authentication, background job processing, and rate limiting.

---

## API Endpoints

### Base URL

```
/api/v1
```

### Authentication Endpoints

| Method | Path              | Request Body                                          | Response                        | Status |
|--------|-------------------|-------------------------------------------------------|---------------------------------|--------|
| POST   | /auth/login       | `{ email: string, password: string }`                 | `{ access_token, refresh_token, user }` | 200    |
| POST   | /auth/refresh     | `{ refresh_token: string }`                           | `{ access_token, refresh_token }`       | 200    |
| DELETE | /auth/logout      | `Authorization: Bearer <token>`                       | `{ message: "Logged out" }`     | 200    |

### Task Endpoints

All task endpoints require `Authorization: Bearer <access_token>` header.

| Method | Path              | Request Body                                                      | Response              | Status |
|--------|-------------------|-------------------------------------------------------------------|-----------------------|--------|
| GET    | /tasks            | Query: `?page=1&per_page=20&status=pending&priority=high&sort=created_at&order=desc` | `{ tasks: [...], meta: { page, per_page, total } }` | 200 |
| POST   | /tasks            | `{ task: { title, description?, priority?, status?, due_date? } }` | `{ task: {...} }`    | 201    |
| GET    | /tasks/:id        | —                                                                 | `{ task: {...} }`    | 200    |
| PATCH  | /tasks/:id        | `{ task: { title?, description?, priority?, status?, due_date? } }` | `{ task: {...} }`  | 200    |
| DELETE | /tasks/:id        | —                                                                 | `{ message: "Deleted" }` | 204    |

---

## Data Models

### User

| Field         | Type      | Constraints                    |
|---------------|-----------|--------------------------------|
| id            | bigint    | PK, auto-increment            |
| email         | string    | unique, not null, indexed      |
| password_digest| string   | not null (bcrypt)              |
| name          | string    | not null                       |
| refresh_token | string    | nullable, indexed              |
| created_at    | datetime  | not null                       |
| updated_at    | datetime  | not null                       |

### Task

| Field       | Type      | Constraints                          |
|-------------|-----------|--------------------------------------|
| id          | bigint    | PK, auto-increment                   |
| user_id     | bigint    | FK → users, not null, indexed        |
| title       | string    | not null, max 255 chars              |
| description | text      | nullable                             |
| status      | enum      | `pending`, `in_progress`, `completed`, `cancelled` (default: `pending`) |
| priority    | enum      | `low`, `medium`, `high`, `urgent` (default: `medium`) |
| due_date    | date      | nullable                             |
| completed_at| datetime  | nullable                             |
| created_at  | datetime  | not null                             |
| updated_at  | datetime  | not null                             |

**Indexes:**
- `idx_tasks_user_id` on `user_id`
- `idx_tasks_status` on `status`
- `idx_tasks_priority` on `priority`
- `idx_tasks_user_status` on `(user_id, status)`

---

## Authentication Flow

### JWT Token Strategy

- **Access Token:** Short-lived (15 minutes), contains `{ user_id, exp, iat }`
- **Refresh Token:** Long-lived (7 days), stored in DB on `users.refresh_token`

### Login Flow

1. Client sends `{ email, password }` to `POST /auth/login`
2. Server validates credentials with `bcrypt`
3. Server generates access + refresh tokens via `JwtService`
4. Refresh token saved to `users.refresh_token`
5. Both tokens returned to client

### Refresh Flow

1. Client sends `{ refresh_token }` to `POST /auth/refresh`
2. Server decodes and validates the refresh token
3. Server verifies token matches stored `users.refresh_token`
4. Server generates new access + refresh tokens
5. New refresh token saved to DB (rotation)
6. New tokens returned to client

### Logout Flow

1. Client sends request with access token
2. Server clears `users.refresh_token` (set to nil)
3. Returns success message

---

## Caching Strategy

### Redis Configuration

- **Connection:** `REDIS_URL` env var (default: `redis://localhost:6379/0`)
- **Cache Store:** `Rails.cache` backed by Redis
- **TTL:** 5 minutes default for task list queries

### What Gets Cached

- Task list queries (per user, per filter combination)
- Individual task reads (invalidated on write)
- User session data during request lifecycle

### Cache Invalidation

- Task create/update/delete triggers cache bust for affected user
- Uses `Rails.cache.delete_matched("user:#{user_id}:tasks:*")` pattern

---

## Background Jobs

### Sidekiq Configuration

- **Queue:** `default`, `notifications`
- **Concurrency:** 10 threads
- **Retry:** 3 attempts with exponential backoff

### Job: `TaskNotificationJob`

- **Trigger:** Enqueued on task create, update, and status changes
- **Purpose:** Send notifications (email, push, webhook) when task state changes
- **Queue:** `notifications`
- **Args:** `{ task_id: Integer, action: String }`

### Job: `TaskCleanupJob` (Planned)

- **Trigger:** Daily cron via sidekiq-cron
- **Purpose:** Archive completed tasks older than 90 days

---

## Error Handling

### Standard Error Response Format

```json
{
  "error": {
    "code": "UNPROCESSABLE_ENTITY",
    "message": "Validation failed",
    "details": {
      "title": ["can't be blank"],
      "priority": ["is not included in the list"]
    }
  }
}
```

### HTTP Status Codes

| Code  | Meaning                   |
|-------|---------------------------|
| 200   | Success                   |
| 201   | Created                   |
| 204   | No Content (delete)       |
| 400   | Bad Request               |
| 401   | Unauthorized              |
| 403   | Forbidden                 |
| 404   | Not Found                 |
| 422   | Unprocessable Entity      |
| 429   | Too Many Requests         |
| 500   | Internal Server Error     |

### Global Exception Handling

The `BaseController` includes `rescue_from` blocks for:
- `ActiveRecord::RecordNotFound` → 404
- `ActiveRecord::RecordInvalid` → 422
- `JWT::DecodeError` / `JWT::ExpiredSignature` → 401
- `ActionController::ParameterMissing` → 400
- `StandardError` → 500 (logged, generic message)

---

## Rate Limiting

### Rack::Attack Configuration

| Category           | Limit              | Window     | Response          |
|--------------------|--------------------|------------|-------------------|
| Login attempts     | 5 requests         | 30 seconds | 429               |
| API (general)      | 100 requests       | 1 minute   | 429               |
| API (per user)     | 300 requests       | 5 minutes  | 429               |
| Task creation      | 20 requests        | 1 minute   | 429               |

### Throttle Strategy

- **Unauthenticated:** Rate limited by IP address
- **Authenticated:** Rate limited by user ID (extracted from JWT)
- **Failed logins:** Track by IP, block after 5 failures in 30s

---

## Versioning

All endpoints are under `/api/v1`. Future versions will be added as `/api/v2`, etc. The API uses header-based versioning:

```
Accept: application/vnd.taskflow.v1+json
```

Content negotiation falls back to URL-based versioning (`/api/v1/...`).

---

## Pagination

Task listing uses offset-based pagination:

```json
{
  "tasks": [...],
  "meta": {
    "current_page": 1,
    "per_page": 20,
    "total_count": 45,
    "total_pages": 3
  }
}
```

Query parameters: `page` (default: 1), `per_page` (default: 20, max: 100).
