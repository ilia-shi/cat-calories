# cat_calories_core

Pure Dart package shared between the Flutter mobile app and the standalone Dart server. **No Flutter dependency allowed.**

## Package structure

```
lib/
  features/
    calorie_tracking/
      domain/           # CalorieRecord, DayResultModel, repository interface
      sync/             # CalorieRecordSyncAdapter
    products/
      domain/           # ProductModel, ProductCategoryModel, repository interfaces
    profile/
      domain/           # ProfileModel, repository interface
    waking_periods/
      domain/           # WakingPeriodModel, repository interface
    oauth/
      domain/           # AuthCredentials, repository interface
    sync/
      domain/           # SyncServer, ScopedServerLink, repository interfaces
      transport/        # SyncTransport interface, SyncEngine, SyncEntry, SyncBatch
        rest/           # REST transport implementation (HTTP client)
      sync_adapter.dart # SyncAdapter<T> base class, SyncAdapterRegistry
      entity_version.dart # HLC-based entity versioning
      envelope.dart     # Envelope<T> wraps entity + version + replica state
      replica.dart      # Per-server replica tracking
      scheduler.dart    # SyncScheduler (periodic sync triggers)
      discover_server.dart # Server discovery via .well-known/sync-config
  http/
    controller.dart     # Base Controller class (CORS, JSON helpers)
    router.dart         # Simple pattern-matching HTTP router
```

## Key rules

- **No Flutter imports** (`package:flutter/*`, `dart:ui`). This package must compile with `dart` alone.
- **No sqflite**. Database implementations live in consumers (Flutter app uses sqflite, standalone server uses sqlite3).
- Domain models use `toJson()` / `fromJson()` with millisecond epoch timestamps.
- Repository interfaces are abstract (`abstract interface class`). Implementations are provided by consumers.
- Sync adapters extend `SyncAdapter<T>` and register via `SyncAdapterRegistry`.

## Consumers

- **Flutter app** (`lib/`): provides sqflite repository implementations, UI, GetIt service locator
- **Standalone server** (`packages/server/`): will provide sqlite3 repository implementations, OAuth middleware, server entry point (planned)

## Commands

```bash
dart pub get                  # resolve dependencies
dart analyze                  # check for errors
dart test                     # run tests (when added)
```
