# Agent guide — Cat Calories

Instructions for AI coding agents working in this repo. Tool-agnostic; any assistant
that reads repo instruction files can use this. (Claude Code reads it via `CLAUDE.md`,
which imports this file.)

## What this is

A calorie-tracking app: a Flutter mobile app (`lib/`) backed by a standalone Dart sync
server (`packages/server`), sharing a pure-Dart domain (`packages/core`), plus a
React/Vite web client (`web/`). The API contract in `api/openapi.yaml` is the single
source of truth — web TypeScript types are generated from it.

See `README.md` for the full feature list and project layout.

## Key references

- **Architecture & adding a feature** → [docs/architecture.md](docs/architecture.md).
  Read this before adding a feature, model, repository, migration, or any import that
  crosses features/layers. It documents the `import_lint` boundaries.
- **UI conventions** → [docs/ui-conventions.md](docs/ui-conventions.md). Read before
  building or editing any widget: reuse shared components, use squircles (not rounded
  rectangles) on rectangular shapes, check spacing/curvature symmetry, and keep widgets
  small (~200-line cap, split into sub-widget classes).
- **Testing & verification** → [docs/testing.md](docs/testing.md). What to run for a
  given change; note that `make test` does not run package-level unit tests.
- **Server specifics** → [packages/server/CLAUDE.md](packages/server/CLAUDE.md)
  (routes, env vars, build/run).

## Rules of thumb

- **Respect the layering.** `packages/core` never imports Flutter or the app. Features
  under `lib/features/<f>` never import sibling features — go through `core`, `common`,
  or `app`. `data/` never imports `ui/`. Details in
  [docs/architecture.md](docs/architecture.md).
- **Keep the API contract in lock-step.** After changing `api/openapi.yaml` or any
  server JSON shape, run `make test-dart` and `make test-web` (the latter regenerates
  `web/src/generated-api.d.ts`).
- **Verify before claiming done.** `flutter analyze` + `make arch` for app/architecture
  changes; `dart test` in the touched package for logic changes. See
  [docs/testing.md](docs/testing.md).

## Common commands

```bash
flutter run            # run the mobile app
make server            # server + web via docker-compose
make dev               # full stack incl. Casdoor OAuth + Traefik
make test              # Dart schema test + web type-check + server analyze
make arch              # import_lint architecture boundary check
```
