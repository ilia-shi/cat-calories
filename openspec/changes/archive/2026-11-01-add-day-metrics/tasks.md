## 1. Core domain

- [x] 1.1 Add `DayMetric` enum in `packages/core/lib/features/metrics/domain/`: key, title, unit, `fromKey` returning null for an unknown key
- [x] 1.2 Add `DayMetricEntry` with `toJson`/`fromJson`, nullable `note` and `deletedAt`, day as text `YYYY-MM-DD`
- [x] 1.3 Add `dayMetricEntryId` (UUID v5 of profile, metric key, day, source under a fixed namespace)
- [x] 1.4 Add `dayMetricError` and whole-number normalization, and formatting including `7 h 30 min`
- [x] 1.5 Add `DayMetricRepositoryInterface` and `DayMetricSyncAdapter` (entity type `day_metric`, scope is the profile)
- [x] 1.6 Unit tests: id stability, day text across time zones, validation limits, zero, rounding, sleep formatting, JSON round trip, sync payload

## 2. Database and repository

- [x] 2.1 Add `V020AddDayMetrics`, register it, set `currentVersion` to 20
- [x] 2.2 Add `day_metric_entries` and its index to `V001InitialSchema`
- [x] 2.3 Add `lib/features/metrics/data/sqlite/day_metric_repository.dart`: upsert that clears `deleted_at`, soft delete, list by profile and day range without deleted rows, `findAll` with them, purge
- [x] 2.4 Repository tests: upsert on the same id, clear then re-enter, deleted rows hidden from lists and present in `findAll`, fresh install schema equals migrated schema

## 3. Sync

- [x] 3.1 Add `DayMetricSyncRepository` and register the adapter in `SyncAdapterRegistry`
- [x] 3.2 Register `DayMetricRepositoryInterface` in `lib/common/service_registry.dart`
- [x] 3.3 Add a `metrics_isolation` rule to `analysis_options.yaml`
- [x] 3.4 Syncer tests in `test/features/metrics/`, through a real folder sync because `Syncer` lives in the app: push of a `day_metric`, unlinked profile skipped, same id from two devices keeps the later `updatedAt`, cleared value arrives as cleared
- [x] 3.5 Server test: a `day_metric` entry is stored and pulled through `sync_entries`

## 4. UI

- [x] 4.1 Add `DayMetricsCubit`: load the day range, save, clear, extend the range
- [x] 4.2 Add `DayMetricInputSheet` from `CalculatorSheet`, `CalculatorFieldDisplay` and `CalculatorKeypad`, with note, Clear on an existing value, the error reason, and the wake-up day hint for sleep
- [x] 4.3 Add `DayMetricsScreen`: rows per day with a cell per metric, dashes, pull-to-refresh, top-bar date action
- [x] 4.4 Add the "Metrics" entry to the app menu in `lib/features/dashboard/ui/app_bar.dart`
- [x] 4.5 Widget tests: dash and 0, sleep typed in hours, rejected value, Clear, reaching an older day, overflow at 360 px width

## 5. Verification

- [x] 5.1 `flutter analyze` and `make arch`
- [x] 5.2 `dart test` in `packages/core` and `packages/server`, and `flutter test`
- [x] 5.3 `make test` and `review-ui` on the new widgets
- [ ] 5.4 Check on a phone: enter, edit and clear values, confirm home and calendar are unchanged, sync between two devices
