# Testing Cat Calories

This is a polyglot workspace. "Run the tests" means more than one command, and the
top-level `make test` target does **not** cover everything. Pick the commands that
match what changed.

## The full gate (`make test`)

```bash
make test        # = test-dart + test-web + test-server
```

What each sub-target actually does (see `Makefile`):

| Target             | Command                                                     | Covers                                                              |
|--------------------|-------------------------------------------------------------|--------------------------------------------------------------------|
| `make test-dart`   | `flutter test test/api_schema_test.dart`                   | Validates Dart controller output matches `api/openapi.yaml` schema |
| `make test-web`    | `cd web && npm run generate:api-types && npx tsc --noEmit` | Regenerates TS API types from OpenAPI, then type-checks the web client |
| `make test-server` | `cd packages/server && dart analyze`                       | **Static analysis only** — does not run server tests               |

## Important gap: `make test` skips real unit tests

`make test` runs only the schema test, web type-check, and a server analyze. It does
**not** run the Dart unit/integration tests in the packages. When logic in
`packages/core` or `packages/server` changed, run them explicitly:

```bash
cd packages/core   && dart test     # syncer, calorie_record_sync_adapter
cd packages/server && dart test     # hlc_generator, sync_v2_handler, sync_entry_repository (integration)
```

## Architecture boundary check (`make arch`)

Separate from `make test`. Enforces the layering and feature-isolation rules in
`analysis_options.yaml` via `import_lint`:

```bash
make arch        # = dart run import_lint
```

Currently `severity: "warning"` (non-breaking), so it reports but does not fail.
Run it after any cross-feature or cross-layer import change. Treat new violations as
regressions even though they don't fail the command. The rules these warnings enforce
are documented in [architecture.md](architecture.md).

## What to run based on what changed

- **`api/openapi.yaml` or any server controller's JSON shape** → `make test-dart`
  (schema) **and** `make test-web` (regenerates `web/src/generated-api.d.ts`). These
  two must stay in lock-step; the OpenAPI file is the single source of truth.
- **`web/` only** → `make test-web` (or `cd web && npm run lint` for ESLint).
- **`packages/core` domain logic** → `cd packages/core && dart test`.
- **`packages/server` handlers/data** → `cd packages/server && dart test` and
  `make test-server` (analyze).
- **Flutter `lib/` widgets/blocs** → `flutter analyze` (no widget test suite exists
  yet beyond the schema test).
- **Any import added/moved across features or layers** → `make arch`.

## Notes

- The Flutter SDK may be invoked via an absolute path on some machines (e.g.
  `/home/ilyashi/Flutter/flutter/bin/flutter`) if bare `flutter` is not on PATH.
- `make test-web` needs `web/node_modules`; run `cd web && npm install` first if
  type generation fails on a missing dependency.
