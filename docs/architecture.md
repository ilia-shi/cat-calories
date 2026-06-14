# Cat Calories architecture & adding a feature

The codebase is split into a **pure-Dart shared domain** (`packages/core`) consumed by
both the Flutter app (`lib/`) and the Dart server (`packages/server`), with strict
import boundaries enforced by `import_lint` (`analysis_options.yaml`). Follow the layer
placement below or `make arch` will report violations.

## Where each piece goes

A feature named `<feature>` (e.g. `products`, `calorie_tracking`, `sync`) spans:

| Layer            | Location                                                  | Contents                                                        |
|------------------|----------------------------------------------------------|----------------------------------------------------------------|
| **Domain**       | `packages/core/lib/features/<feature>/domain/`           | Plain models (`final class X`, with `fromJson`) + `abstract interface class XRepositoryInterface` |
| **Data (app)**   | `lib/features/<feature>/data/sqlite/`                     | `class XRepository implements XRepositoryInterface` over sqflite |
| **UI**           | `lib/features/<feature>/ui/`                              | Screens/widgets; blocs                                          |
| **DB schema**    | `lib/database/migrations/vNNN_*.dart`                     | New tables/columns (see Migrations below)                       |
| **DI**           | `lib/common/service_registry.dart`                        | Register the repository against its interface                  |

The server (`packages/server`) reuses the same `packages/core` domain models and its
own data layer under `packages/server/lib/data/`.

## Architecture rules (enforced by `import_lint`)

These are the boundaries `make arch` checks. Respect them when choosing imports:

1. **`packages/core` imports nothing from the app or Flutter.** It's pure Dart — this
   is compiler-enforced (Flutter isn't in its pubspec). Domain models and repository
   *interfaces* live here so the server can reuse them.
2. **Feature isolation:** a feature under `lib/features/<feature>/**` must **not**
   import a *sibling* feature (`features/<other>/**`). Each feature has an
   `<feature>_isolation` rule. Cross-feature needs go through:
   - `packages/core` (shared domain),
   - `lib/common/**` (theme, widgets, utils — feature-agnostic),
   - `lib/app/**` (shared application state, e.g. `HomeBloc`).
   - **Exception:** `features/dashboard` is the aggregator/composition UI and *may*
     depend downward on leaf features.
3. **Layer direction:** `features/**/data/**` must not import `features/**/ui/**` or
   `common/widgets/**`. Data never reaches "up" into UI.
4. **`common/` stays feature-agnostic:** `common/theme/**`, `common/widgets/**`,
   `common/utils/**` must not import any `features/**`. (The DI composition root
   `common/service_registry.dart` is exempt — it legitimately knows every feature.)

Severity is currently `warning`, so violations don't fail the build — but treat any
new one as a regression to fix, not ignore.

## Step-by-step: new entity + repository

1. **Domain model** → `packages/core/lib/features/<feature>/domain/<entity>.dart`.
   Pattern: `final class <Entity>` with fields, a named constructor, and a
   `factory <Entity>.fromJson(Map<String, dynamic> json)` (see
   `packages/core/lib/features/products/domain/product_category.dart` for the
   defensive `_parseInt` / null-tolerant style).
2. **Repository interface** →
   `packages/core/lib/features/<feature>/domain/<entity>_repository_interface.dart`:
   `abstract interface class <Entity>RepositoryInterface { ... }`.
3. **App implementation** →
   `lib/features/<feature>/data/sqlite/<entity>_repository.dart`:
   `class <Entity>Repository implements <Entity>RepositoryInterface`, takes a
   `DatabaseClient` in its constructor, defines `static const String tableName`, uses
   `package:uuid` for ids (see `lib/features/products/data/sqlite/product_repository.dart`).
4. **Migration** for the new table/columns (see below).
5. **Register DI** in `lib/common/service_registry.dart`:
   ```dart
   locator.registerLazySingleton<XRepositoryInterface>(
     () => XRepository(locator.get<DatabaseClient>()),
   );
   ```
6. **UI** under `lib/features/<feature>/ui/`. Resolve repositories via
   `locator.get<XRepositoryInterface>()`.
7. **Verify:** run `flutter analyze` and `make arch`. If the entity syncs to the
   server, also register a sync adapter (see Sync below) and update
   `api/openapi.yaml` (then `make test-dart` + `make test-web`).

## Migrations

`lib/database/migrations/` holds versioned `Migration` subclasses. To add one:

1. Create `vNNN_<description>.dart` with the next number (check the directory for the
   real highest before picking N).
2. Implement `up(Database db)` and set `version` to NNN.
3. Register it in `lib/database/migration_runner.dart`: add the import, append the
   instance to the `_migrations` list, and bump `currentVersion` to NNN.
   (`onCreate` runs `V001InitialSchema`; `onUpgrade` replays migrations with
   `version > oldVersion`.)

## Sync (only if the entity replicates to the server)

Syncable entities register a `SyncAdapter` + sync repository in the
`SyncAdapterRegistry` block of `service_registry.dart` (there's a
`// Register more entity types here:` marker). The adapter lives in
`packages/core/lib/features/<feature>/sync/`, the app-side sync repo in
`lib/features/<feature>/data/`. Mirror the `calorie_tracking` wiring as the template.
Server-side sync is handled by `packages/server/lib/handler/sync_v2_handler.dart`.

## Always finish with

```bash
flutter analyze       # app compiles & lints
make arch             # no new boundary violations
```
Plus `make test-dart` + `make test-web` if you touched the API contract. See
[testing.md](testing.md) for the full matrix.
