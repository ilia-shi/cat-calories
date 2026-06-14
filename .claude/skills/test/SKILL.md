---
name: test
description: Run the Cat Calories test and verification suite. Use when asked to run tests, verify changes, check the build, validate the API contract, or confirm the feature-architecture boundaries still hold. Covers the Flutter app, the pure-Dart core/server packages, the React/TypeScript web client, and the import_lint architecture check.
---

# Testing Cat Calories

The full, tool-agnostic testing guide lives in [docs/testing.md](../../../docs/testing.md).
Read it for the command matrix and gotchas. Quick reference:

```bash
make test     # Dart API-schema test + web type-check (regenerates TS types) + server analyze
make arch     # import_lint architecture boundary check (warnings)
```

`make test` does **not** run the package-level Dart unit tests — run those explicitly
when `packages/core` or `packages/server` logic changed:

```bash
cd packages/core   && dart test
cd packages/server && dart test
```

After changing `api/openapi.yaml` or any server JSON shape, run `make test-dart` **and**
`make test-web` — they must stay in lock-step. Full per-change guidance:
[docs/testing.md](../../../docs/testing.md).
