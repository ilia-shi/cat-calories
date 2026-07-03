---
name: add-feature
description: Scaffold or extend a feature in the Cat Calories app following its feature-first, layered architecture. Use when adding a new feature (or a new entity/repository within one), creating a domain model + repository, wiring dependency injection, or adding a database migration. Encodes the import_lint boundary rules so new code does not introduce architecture violations. Do NOT use for pure UI tweaks inside an existing widget, or for changes that add no model/repository/migration.
---

# Adding a feature to Cat Calories

**Before scaffolding anything, read [docs/architecture.md](../../../docs/architecture.md)
in full** — it has the layer table, code-pattern examples, and the migration/sync
wiring. This skill inlines the rules you must not break and the order to do things in,
so that even without re-reading the doc you won't introduce a boundary violation.

## Where each piece goes (memorize this table)

| Layer | Location |
|---|---|
| **Domain** (models + repository *interfaces*, pure Dart) | `packages/core/lib/features/<feature>/domain/` |
| **Data** (sqflite repository impls) | `lib/features/<feature>/data/sqlite/` |
| **UI** (screens, widgets, blocs) | `lib/features/<feature>/ui/` |
| **DB schema** (new tables/columns) | `lib/database/migrations/vNNN_*.dart` |
| **DI** (register impl against interface) | `lib/common/service_registry.dart` |

The server (`packages/server`) reuses the same `packages/core` domain models, with its
own data layer under `packages/server/lib/data/`.

## The four boundaries you must NOT cross (`make arch` enforces these)

1. **`packages/core` imports nothing from the app or Flutter.** Pure Dart only. Domain
   models and repository *interfaces* live here so the server can reuse them.
2. **No sibling-feature imports.** Code under `lib/features/<feature>/**` must not import
   `lib/features/<other>/**`. Cross-feature needs go through `packages/core` (shared
   domain), `lib/common/**` (feature-agnostic theme/widgets/utils), or `lib/app/**`
   (shared app state). **Only exception:** `features/dashboard` may depend downward on
   leaf features.
3. **Data never imports UI.** `features/**/data/**` must not import `features/**/ui/**`
   or `common/widgets/**`.
4. **`common/` stays feature-agnostic.** `common/theme/**`, `common/widgets/**`,
   `common/utils/**` must not import any `features/**`. (Only `common/service_registry.dart`,
   the DI root, is exempt.)

Severity is `warning` today — treat any new violation as a regression to fix, not ignore.

## Step-by-step: new entity + repository

Do these in order. Do not skip the verify step.

1. **Domain model** → `packages/core/lib/features/<feature>/domain/<entity>.dart`.
   `final class <Entity>` with fields, a named constructor, and a
   `factory <Entity>.fromJson(...)`. Copy the null-tolerant style from
   `packages/core/lib/features/products/domain/product_category.dart`.
2. **Repository interface** → same domain folder,
   `abstract interface class <Entity>RepositoryInterface { ... }`.
3. **App implementation** → `lib/features/<feature>/data/sqlite/<entity>_repository.dart`:
   `class <Entity>Repository implements <Entity>RepositoryInterface`, takes a
   `DatabaseClient`, has `static const String tableName`, uses `package:uuid` for ids.
   Model on `lib/features/products/data/sqlite/product_repository.dart`.
4. **Migration** (see next section).
5. **Register DI** in `lib/common/service_registry.dart`:
   ```dart
   locator.registerLazySingleton<XRepositoryInterface>(
     () => XRepository(locator.get<DatabaseClient>()),
   );
   ```
6. **UI** under `lib/features/<feature>/ui/`; resolve repos via
   `locator.get<XRepositoryInterface>()`.
7. **Verify** (mandatory): `flutter analyze` **and** `make arch`. If the entity syncs,
   also update `api/openapi.yaml` then run `make test-dart` + `make test-web`.

## Migration (if you added a table or column)

1. Create `lib/database/migrations/vNNN_<description>.dart` — **check the directory for
   the current highest N first**, then use N+1.
2. Implement `up(Database db)`; set `version` to NNN.
3. Register in `lib/database/migration_runner.dart`: add the import, append the instance
   to `_migrations`, and bump `currentVersion` to NNN.

## Sync (only if the entity replicates to the server)

Register a `SyncAdapter` + sync repo in the `SyncAdapterRegistry` block of
`service_registry.dart` (look for `// Register more entity types here:`). Adapter →
`packages/core/lib/features/<feature>/sync/`; app-side sync repo →
`lib/features/<feature>/data/`. Mirror the `calorie_tracking` wiring. Server side is
`packages/server/lib/handler/sync_v2_handler.dart`. Full detail:
[docs/architecture.md](../../../docs/architecture.md).

## Final checklist — answer yes to all before claiming done

- [ ] Each new file is in the correct layer folder from the table above.
- [ ] No import crosses any of the four boundaries (domain has no Flutter; no
      sibling-feature import; data doesn't import ui; common doesn't import features).
- [ ] Repository registered in `service_registry.dart` against its **interface**.
- [ ] If schema changed: migration created with the next N and registered + `currentVersion` bumped.
- [ ] `flutter analyze` clean **and** `make arch` reports no new violation.
- [ ] If the API contract changed: `make test-dart` + `make test-web` both pass.
