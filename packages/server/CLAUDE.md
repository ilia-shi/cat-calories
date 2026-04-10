# cat_calories_server

Standalone Dart HTTP server for Cat Calories. Replaces the previous Go server (`server/`).

## Structure

```
bin/
  server.dart             # Entry point — HTTP server, routing, static files
lib/
  config/
    config.dart           # ServerConfig from environment variables
  auth/
    auth_middleware.dart   # TokenAuth (HMAC), UserExtractor, requireAuth()
  data/sqlite/
    database.dart         # openDatabase(), migrations
    user_repository.dart  # User CRUD, password hashing
    profile_repository.dart       # implements ProfileRepositoryInterface
    calorie_record_repository.dart # implements CalorieRecordRepositoryInterface
    sync_entry_repository.dart    # HLC generator, push/pull sync storage
  handler/
    health_handler.dart     # GET /health
    auth_handler.dart       # POST /auth/register, /auth/login
    discovery_handler.dart  # GET /.well-known/sync-config
    sync_v2_handler.dart    # POST /api/v1/sync/push, GET /api/v1/sync/pull
```

## Dependencies

- `cat_calories_core` — domain models, repository interfaces, HTTP base classes
- `sqlite3` — native SQLite (NOT sqflite, which is Flutter-only)
- `crypto` — password hashing, HMAC token signing

## API Routes

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | /health | No | Health check with DB status |
| GET | /.well-known/sync-config | No | Server discovery for mobile client |
| POST | /auth/register | No | Create user, returns token |
| POST | /auth/login | No | Login, returns token |
| POST | /api/v1/sync/push | Bearer | Push sync entries (with idempotency + conflict detection) |
| GET | /api/v1/sync/pull | Bearer | Pull sync entries since HLC |

## Environment variables

| Variable | Default | Description |
|----------|---------|-------------|
| DATABASE_PATH | ./data.db | SQLite database file path |
| SERVER_PORT | 8080 | HTTP listen port |
| SERVER_SECRET | (empty) | HMAC secret for token signing |
| WEB_DIST_PATH | (none) | Path to web frontend dist/ for static serving |
| SERVER_NAME | Cat Calories Sync | Server display name |
| SERVER_VERSION | 2.0.0 | Version reported in health/discovery |
| SERVER_BASE_URL | http://localhost:8080 | Base URL for discovery |
| OAUTH_ENDPOINT | http://casdoor:8000 | OAuth provider endpoint |
| OAUTH_CLIENT_ID | (empty) | OAuth client ID (empty = disabled) |
| OAUTH_CLIENT_SECRET | (empty) | OAuth client secret |
| OAUTH_ORGANIZATION | built-in | OAuth organization |
| OAUTH_APPLICATION | cat-calories | OAuth application name |

## Commands

```bash
dart pub get
dart analyze
dart run bin/server.dart                    # run locally
dart compile exe bin/server.dart -o server  # compile native binary
```

## Database

Uses SQLite with WAL mode. Schema matches the mobile app's calorie_items/products/profiles tables, using millisecond epoch timestamps (same format as core domain models' toJson/fromJson).

Sync uses HLC (Hybrid Logical Clock) timestamps for causal ordering. The sync_entries table stores the full entity payload as JSON.

## Docker

```bash
# From repo root:
docker build -f packages/server/Dockerfile -t cat-calories-server .
docker run -p 8080:8080 -v data:/data -e DATABASE_PATH=/data/data.db cat-calories-server
```
