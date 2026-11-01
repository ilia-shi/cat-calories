## Context

`calendarCells` in core builds food cells from `DayNutrition`, and every calendar widget
under `lib/features/calorie_tracking/ui/calendar/` takes a `CalendarCell`. `CalendarDay`
and `calendarBar` are about kcal, statuses and a goal. A metric has none of these: no
status, no goal, and absence means unknown.

`features/calorie_tracking` cannot import `features/metrics`, but both can read
`DayMetricRepositoryInterface` from core.

## Goals / Non-Goals

**Goals:**
- Follow one metric by day, week and month in the widget and the full screen.
- Keep food mode unchanged.

**Non-Goals:**
- Editing a value from the calendar. `DayMetricInputSheet` lives in a sibling feature,
  and moving it is not worth it while the Metrics screen covers editing.
- `≥` on metric values. It belongs to gaps for metrics (B2).
- Comparing metrics with each other or with a personal baseline (A3).
- Choosing between sources (A4). Every entry is `manual` today.

## Decisions

### A separate `MetricCell`, not a nullable `CalendarCell`

`metricCells` in `packages/core/lib/features/metrics/domain/metric_cells.dart` returns
`MetricCell`: `start`, `end`, `mode`, `metric`, `days` and the aggregates. `CalendarCell`
stays as it is. Alternative: making `CalendarCell` generic. Rejected: every field except
the period and days would be nullable or meaningless for a metric.

Cells run from the period of the metric's earliest value to the period holding today,
including periods without values, as food cells do.

### Aggregation belongs to the metric

`DayMetric` gains `aggregation`: `sum` for steps and burned kcal, `average` for sleep.

- `sum`: the cell shows the sum of all days with a value, today included. Details add the
  average per day over days with a value, without today, since today is unfinished. This
  matches food: the cell has the full sum, the tap has the average.
- `average`: the cell shows the average over days with a value, today included, since a
  night that ended today is complete. A sum of sleep means nothing.

Only days with a value count, because absence means unknown, never 0. A saved 0 counts.
A sum therefore covers fewer days when values are missing; details say how many, as
`5 of 7 days`. It gets no `≥`, because that mark is reserved for gaps.

### Fixed bar scale per metric

`DayMetric` gains `barFull`: 20000 steps, 720 minutes of sleep, 5000 kcal burned. The
reason is the one behind the food scale: taken from the largest day, one long hike would
flatten the history. These are starting values. A day above `barFull` is drawn at full
height in the normal colour, because no metric has a goal to exceed, and there is no
goal line.

### `CalendarBars` takes bars instead of days

`CalendarBars` and its painter receive `List<CalendarBar>` and `showGoalLine`. Food maps
`calendarBar` over its days, and metrics map a new `metricBar`. A past day without a value
is `blank`, not `emptySlot`: that tint means "mark this day", and metrics never prompt.

### The chosen content is a new cubit

`CalendarContentCubit` in `lib/app/state/` holds `DayMetric?`, where null means food. It
sits above the navigator next to `CalendarModeCubit` for the same reasons. Keeping them
apart leaves every existing `CalendarMode` reader untouched.

The strip's menu gains a checked group Food, Steps, Sleep, Burned, and the full screen a
second row of `ModeButton`. The strip's title becomes `Steps · Weeks`, with
`Calendar · Weeks` for food.

### Widgets

`CalendarData` gains `metricEntries`, defaulting to empty, and `metricCells(metric, mode)`,
cached per pair. `CalendarDataBuilder` loads entries with the rest.

`CalendarItem`, with a food and a metric implementation, gives `CalendarCellCard`, the
full-screen row and the month grid the period, value, bars and details action, so each
widget has one path for both contents. `shortPeriodLabel` and `fullPeriodLabel` take
`start`, `end` and `mode`, not a cell.

`CalendarMetricSheet` shows one row per metric for a period. The rows are a shared widget,
`CalendarMetricRows`, which `CalendarCellSheet` also uses.

### Formats

Steps and kcal use `formatAmount`: no decimals, and `K` in weeks and months. Sleep in a
cell is compact, `7h 30m`, because a cell is 56 px wide, and details use `7 h 30 min`.

### Refresh after a change

`CalendarDataBuilder` reloads on `HomeFetched`, and saving a metric does not emit one.
`DayMetricsScreen` adds `CalorieItemListFetchingInProgressEvent` once when it closes, if
something changed. Reloading on every save would rebuild the home screen behind the
sheet for nothing.

## Risks / Trade-offs

- [A fixed scale does not fit a person walking 30000 steps daily] → bars cap at full
  height and the number stays right. `barFull` can move to settings later.
- [Metric rows in food details grow the sheet] → it already scrolls, and a metric without
  a value adds no row.
- [Changing `CalendarBars`, the labels and the grid touches food code] → existing calendar
  tests cover food mode and must pass unchanged, except for the new parameters.

## Migration Plan

None. No stored data changes.
