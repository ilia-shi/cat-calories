# Cat Calories

A calorie-tracking app built with Flutter, backed by a Dart sync server. Track food
intake across custom waking periods, browse a built-in nutritional database, manage
multiple profiles, and sync records across devices (or view/edit them from a browser).

## Features

- **Calorie tracking** -- log food entries with calories, protein, fat, and carbs; view daily and period-based summaries
- **Waking periods** -- define time-bounded periods (e.g. a work shift) with their own calorie goals, instead of only tracking by calendar day
- **Built-in food database** -- hundreds of products with nutritional info per 100g, organized by category with search
- **Custom products** -- create and manage your own products with full nutritional info, categories, and barcodes
- **Multiple profiles** -- separate calorie goals, waking durations, and history per profile
- **Smart recommendations** -- rolling calorie tracker with a compensation algorithm that adjusts targets based on historical eating patterns
- **Calorie history** -- browse past entries by date with daily summaries, averages, and macro breakdowns
- **Data export** -- export today's, current period's, or all data to JSON and share
- **Device sync** -- push/pull records to a Dart sync server using HLC (Hybrid Logical Clock) timestamps for conflict-free ordering; optional OAuth login via Casdoor
- **Embedded web server** -- start an HTTP server on the device to view and edit records from another device on the same network
- **Web client** -- a React/Vite frontend for viewing and editing records from a browser
- **Dark / light theme** -- system, light, or dark mode

## Architecture

The project is a multi-target Dart workspace. A pure-Dart **shared domain**
(`packages/core`) is consumed by both the Flutter app and the standalone server, so
the same models, repository interfaces, and sync logic run on mobile and backend.

```
lib/                         -- Flutter app
  app/                       -- shared application state (HomeBloc) + ProfileResolver
  common/                    -- feature-agnostic shared layer
    theme/  widgets/  utils/ -- reusable UI building blocks
    service_registry.dart    -- get_it dependency-injection composition root
    locator.dart
  database/                  -- sqflite client + versioned migrations/
  features/                  -- feature-first modules, each with data/ and ui/
    calorie_tracking/
    products/
    profile/
    waking_periods/
    planning/
    sync/                    -- device sync UI + local storage
    oauth/                   -- Casdoor OAuth login
    embedded_server/         -- on-device HTTP server
    dashboard/               -- aggregator/composition UI (tabs, drawer)
  main.dart

packages/
  core/                      -- pure Dart shared domain (NO Flutter)
    features/<feature>/domain/   -- models + repository interfaces
    features/<feature>/sync/     -- sync adapters
    http/                        -- shared HTTP router/base classes
  server/                    -- standalone Dart HTTP/sync server (replaces the old Go server)
    bin/server.dart, lib/{config,auth,data/sqlite,handler}/
  seeder/                    -- built-in product seed data

web/                         -- React 19 + Vite + TypeScript browser client
api/openapi.yaml             -- API contract (single source of truth; web TS types are generated from it)
proto/sync/                  -- sync protocol definitions
docker-compose.yaml          -- local stack: server(s), web, Casdoor (OAuth), Traefik
```

### Architecture boundaries

Import boundaries are enforced by `import_lint` (see `analysis_options.yaml`,
`make arch`):

- `packages/core` imports nothing from the app or Flutter (compiler-enforced — Flutter
  is not in its pubspec). Shared domain lives here so the server can reuse it.
- Features under `lib/features/<feature>` must not import sibling features. Cross-feature
  needs go through `packages/core`, `lib/common`, or `lib/app`. (`dashboard` is the
  composition root and may depend downward on leaf features.)
- `features/**/data` must not import `features/**/ui` or `common/widgets`.
- `common/theme`, `common/widgets`, `common/utils` stay feature-agnostic.

## Tech stack

- **App state management**: flutter_bloc
- **Dependency injection**: get_it
- **App database**: sqflite (SQLite) with versioned migrations
- **Server**: standalone Dart (`package:sqlite3`, HMAC token auth, HLC sync)
- **Web client**: React + Vite + TypeScript (API types generated from `api/openapi.yaml`)
- **Auth**: Casdoor (OAuth), optional
- **Infra**: docker-compose + Traefik
- **Fonts**: Ubuntu

## Getting started

### Mobile app

```bash
flutter pub get
flutter run
```

Build a release APK:

```bash
flutter build apk        # or: make build
```

### Server + web stack (local)

```bash
make server      # server + web via docker-compose
make dev         # full stack incl. Casdoor OAuth + Traefik, with health checks
make server-run  # run just the Dart server locally, without Docker
```

See `Makefile` for the full set of targets (emulators, android wireless debugging,
firewall, logs). Server details and environment variables are documented in
`packages/server/CLAUDE.md`.

## Testing

```bash
make test        # Dart API-schema test + web type-check + server analyze
make arch        # import_lint architecture boundary check (warnings)
```

`make test` does not run the package-level Dart unit tests; run those explicitly:

```bash
cd packages/core   && dart test
cd packages/server && dart test
```

## Requirements

- Flutter SDK >= 3.0.0 (Dart >= 3.0.0)
- Android SDK for building the mobile app
- Docker + Docker Compose for the server/web stack
- Node.js for the web client
