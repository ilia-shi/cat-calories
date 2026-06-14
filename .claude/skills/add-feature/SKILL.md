---
name: add-feature
description: Scaffold or extend a feature in the Cat Calories app following its feature-first, layered architecture. Use when adding a new feature (or a new entity/repository within one), creating a domain model + repository, wiring dependency injection, or adding a database migration. Encodes the import_lint boundary rules so new code does not introduce architecture violations.
---

# Adding a feature to Cat Calories

The full, tool-agnostic guide — layer placement, the four `import_lint` boundary rules,
the step-by-step for a new entity/repository, migrations, and sync wiring — lives in
[docs/architecture.md](../../../docs/architecture.md). Read it before scaffolding.

Quick orientation:

- **Domain** (models + repository interfaces) → `packages/core/lib/features/<feature>/domain/`
  (pure Dart, reused by app and server).
- **Data** (sqflite repository impls) → `lib/features/<feature>/data/sqlite/`.
- **UI** → `lib/features/<feature>/ui/`.
- **DI** → register against the interface in `lib/common/service_registry.dart`.
- **Migrations** → `lib/database/migrations/vNNN_*.dart` + register in `migration_runner.dart`.

Boundaries to respect: `core` imports no Flutter/app; features don't import sibling
features (go through `core`/`common`/`app`); `data/` never imports `ui/`. Finish with
`flutter analyze` + `make arch`. Details and code-pattern examples:
[docs/architecture.md](../../../docs/architecture.md).
