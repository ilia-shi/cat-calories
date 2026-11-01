## Why

Metrics recorded on the Metrics screen can only be read day by day, so steps or sleep
cannot be followed over weeks and months, which is why they are recorded. The calendar
already groups by day, week and month, so it is the place to show them.

## What Changes

- The calendar can show food (default) or one metric: steps, sleep or burned kcal. The
  choice is shared by the widget and the full screen and lasts until the app is closed.
- A metric cell shows the period's value by the metric's own rule: a sum for steps and
  burned kcal, an average per night for sleep. A period without values shows `—`.
- A metric cell has one bar per day on a fixed scale per metric, so any two cells compare
  directly. A day without a value has no bar and no highlight.
- Tapping a metric cell shows all metrics of the period. Food details gain the same
  metric rows when the period has values.
- The calendar refreshes after a value is saved or cleared on the Metrics screen.

Editing stays on the Metrics screen. Comparison, gaps for metrics, Health Connect import
and the LLM export are later increments.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `nutrition-calendar`: the calendar shows metrics, and cell details list them.

## Impact

- `packages/core/lib/features/metrics/domain/`: `MetricCell`, `metricCells`, aggregation
  and bar scale on `DayMetric`. `periodStart` and `nextPeriod` become public in
  `calendar_cells.dart`.
- `lib/app/state/`: new `CalendarContentCubit`, provided in `lib/main.dart`.
- `lib/features/calorie_tracking/ui/calendar/`: data builder, strip, full screen, month
  grid, bars, labels, `CalendarItem` and a metric details sheet.
- `lib/features/metrics/ui/`: `DayMetricsScreen` asks `HomeBloc` to reload after a change.
- No migration, no sync change, no API change.
