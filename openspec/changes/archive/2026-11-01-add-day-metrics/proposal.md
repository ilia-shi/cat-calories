## Why

The app records food only, so the user cannot compare it over time with steps, sleep or
burned calories. Those numbers live in other apps or nowhere, and every day not recorded
is history lost. This change starts that history with manual input, before any device
arrives, and gives later Health Connect import and comparison a place to write and read.

## What Changes

- New `DayMetric` abstraction: one number per metric and day, for steps, sleep and burned
  kcal. The metric list is fixed in core, and each metric declares its unit.
- A "Metrics" entry in the app menu opens a screen with days, newest first, and the
  values of each day. Past days can be filled in and edited.
- A value is entered in a calculator sheet and carries an optional note. Nothing is
  required, an empty value shows a dash, and nothing is highlighted or prompted.
- Values sync between devices as a new entity type `day_metric`.
- Burned kcal is stored for relative comparison only. It does not touch the calorie
  budget, the recommendations or any food statistic.
- A migration adds the `day_metric_entries` table.

Later increments, not part of this change: metrics in the calendar, comparison, Health
Connect import, tracking gaps for metrics, custom metrics, LLM export.

## Capabilities

### New Capabilities

- `day-metrics`: recording, editing and listing one number per metric and day.

### Modified Capabilities

- `sync`: `day_metric` joins the synced entity types and the profile scope, and the
  server keeps it in the sync log only.

## Impact

- `packages/core/lib/features/metrics/`: `DayMetric`, `DayMetricEntry`, repository
  interface, `DayMetricSyncAdapter`. No Flutter imports.
- `lib/features/metrics/`: sqflite repository, sync repository, `DayMetricsCubit`,
  `DayMetricsScreen`, `DayMetricInputSheet`.
- `lib/database/migrations/v020_add_day_metrics.dart`, `v001_initial_schema.dart`,
  `migration_runner.dart`.
- `lib/common/service_registry.dart`, `lib/features/dashboard/ui/app_bar.dart`,
  `analysis_options.yaml` (new `metrics_isolation` rule).
- No new dependency, no permission, no `api/openapi.yaml` change, no web UI.
