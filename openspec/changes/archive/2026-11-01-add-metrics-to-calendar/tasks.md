## 1. Core

- [x] 1.1 Add `MetricAggregation`, `aggregation` and `barFull` to `DayMetric`, and compact sleep formatting (`7h 30m`)
- [x] 1.2 Make `periodStart` and `nextPeriod` public in `calendar_cells.dart`
- [x] 1.3 Add `MetricCell`, `metricCells`, `metricCellFor` and `metricBar` in `metric_cells.dart`
- [x] 1.4 Unit tests: periods with and without values, sum, average, saved zero, today in the sum and out of the average, sleep average with today, only today, deleted and unknown entries ignored, K format, bar kinds and full height

## 2. State and data

- [x] 2.1 Add `CalendarContentCubit` in `lib/app/state/` and provide it in `lib/main.dart`
- [x] 2.2 Add `metricEntries` and cached `metricCells` to `CalendarData`, and load entries in `CalendarDataBuilder`

## 3. Shared calendar widgets

- [x] 3.1 Change `CalendarBars` and its painter to take bars and `showGoalLine`, and update food callers
- [x] 3.2 Change `shortPeriodLabel` and `fullPeriodLabel` to take `start`, `end` and `mode`
- [x] 3.3 Change `CalendarMonthGrids` to take pairs of day and cell widget

## 4. Metric UI

- [x] 4.1 Add `CalendarItem`, so `CalendarCellCard`, the full-screen row and the month grid draw food and metrics through one path
- [x] 4.2 Add content choice to the strip's menu and title, and the empty text
- [x] 4.3 Add the content row, metric list and metric grid to `CalendarScreenBody`
- [x] 4.4 Add `CalendarMetricRows` and `CalendarMetricSheet`, and the rows in `CalendarCellSheet`
- [x] 4.5 Make `DayMetricsScreen` request a home reload on close after a change
- [x] 4.6 Widget tests: choosing a metric, every mode and content at 360 px, full screen, details with note, rows in food details, no values text, reload only after a change

## 5. Verification

- [x] 5.1 `flutter analyze` and `make arch`
- [x] 5.2 `dart test` in `packages/core` and `flutter test`, with existing calendar tests passing
- [x] 5.3 `review-ui` on the changed widgets
- [ ] 5.4 Check on a phone: scroll metrics in every mode, open details, save a value and return to the calendar
