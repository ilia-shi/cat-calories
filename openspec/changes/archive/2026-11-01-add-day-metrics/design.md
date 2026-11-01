## Context

The app has no per-day number other than what it derives from calorie records.
`packages/core/lib/features/activity_tracking/` holds `TrackingMetric` and `MetricValue`,
but those describe what an exercise set measures, nothing uses them, and workouts are a
separate track. `TrackingGap` is the closest precedent: a synced, profile-scoped entity
kept only in `sync_entries` on the server, with a soft delete.

Later increments shape this table: Health Connect import (A4) adds imported rows and
custom metrics (A6) add keys. Neither should need a migration of this table.

## Goals / Non-Goals

**Goals:**
- One value per metric, day and source, editable for any past day.
- Sync that yields one row when two phones enter the same day.
- A table that A4 and A6 can use unchanged.

**Non-Goals:**
- Metrics in the calendar, aggregation by week or month, comparison and baselines.
- Health Connect import, and the rule choosing between manual and imported values.
- Gaps for metrics. Absence already means unknown.
- Custom metrics, workouts, the LLM export, web UI and server statistics.

## Decisions

### A new `metrics` feature with the name `DayMetric`

`lib/features/metrics/` and `packages/core/lib/features/metrics/`. Metrics are not food,
so `calorie_tracking` is the wrong home, and A3 will read both through core.
`features/dashboard` may import a leaf feature, so the app menu can open the screen.

`DayMetric` avoids `TrackingMetric` and `MetricValue` from `activity_tracking`.

### Fixed metrics in core, stored as a text key

`DayMetric` is an enum: `steps`, `sleepMinutes`, `burnedKcal`, with keys `steps`,
`sleep_minutes`, `burned_kcal`, plus title and unit. The column is text, so A6 adds
custom keys without a migration. An entry with an unknown key, pulled from a newer app
version, is kept in the database and not shown.

Alternative: a `day_metrics` definitions table now. Rejected: it would add a synced
entity and a management UI with nothing to manage.

### Day stored as text `YYYY-MM-DD`

`calorie_items.record_day` is local midnight in milliseconds divided by 100000, so the
same calendar day gets a different number in another time zone. A metric answers for a
calendar day, and the day is part of the id below, so it is stored as a date string that
never shifts. This replaces `record_day` from the working plan. A2 compares days through
`dayOf`, so the two formats need one parse only.

### Deterministic id

The id is a UUID v5 of profile id, metric key, day and source, under a fixed namespace
constant. Two phones entering the same day therefore write one entity, and the existing
rule resolves it: a pulled entry overwrites only when its `updatedAt` is strictly later.
Random ids would leave two rows for one day after sync.

This makes the id the uniqueness constraint, so no separate unique index is needed.

### `source` column from the start

Not null, always `manual` in this change. The id depends on it, so adding it in A4 would
change the id of every existing row. The rule that manual beats imported belongs to A4.

### Soft delete, and saving revives

`deleted_at` as on `TrackingGap`, because Syncer never pushes a deletion from the phone.
Since the id is deterministic, entering a value after clearing it hits the same row, so
`save` is an upsert that clears `deleted_at`. `findAll` for sync returns deleted rows,
list queries do not.

### Values are normalized when saved

`value` is `REAL`, so all metrics share a column. Saving rounds to a whole number: steps,
minutes of sleep, kcal. Sleep is typed in hours, 7.5 becomes 450 minutes, and shows as
`7 h 30 min`. Validation in core, `dayMetricError`, rejects a negative value, sleep above
1440 minutes and a future day. Zero is a valid value: it is distinct from no row, and
clearing is the delete action.

Sleep belongs to the day of waking up. The sheet says so.

### Screen and sheet

`DayMetricsScreen` shows one row per calendar day, newest first, from today back to the
older of 30 days ago and the oldest entry. A row has one cell per metric, and tapping a
cell opens `DayMetricInputSheet` for that metric and day. A top-bar action picks any past
date and extends the list to it, which is how older days are reached.

`DayMetricInputSheet` reuses `CalculatorSheet`, `CalculatorFieldDisplay` and
`CalculatorKeypad`, with a note field and a Clear action on an existing value.
`DayMetricsCubit` lives in the feature and loads through the repository interface.
`HomeBloc` stays out of it: nothing on the home screen reads metrics yet.

### Server keeps entries in the sync log

The sync handler stores any entity type in `sync_entries`, so the server needs no code.
Nothing on the server reads metrics in this change.

## Risks / Trade-offs

- [Older app version on another phone] → it has no adapter for `day_metric`, so it
  neither pushes nor pulls these entries. They arrive after that phone updates.
- [Two phones edit one day offline] → the later `updatedAt` wins and the other value is
  lost. Acceptable for one number per day.
- [`DayMetricsScreen` shows stale data after a background sync] → it reloads on open.
  Pull-to-refresh is enough for this increment.
- [An unknown key stays invisible] → only possible after a downgrade or with A6 on
  another phone, and the row is kept rather than dropped.

## Migration Plan

`V020AddDayMetrics` creates `day_metric_entries` with an index on `(profile_id, day)`,
and `V001InitialSchema` gets the same table because a fresh install runs nothing else.
`currentVersion` becomes 20. Rollback: the app stops using the table; it is not dropped.
