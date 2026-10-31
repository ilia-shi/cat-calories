## 1. Domain

- [x] 1.1 Add `DayNutrition` and `fetchDayNutrition(profile)` to `CalorieRecordRepositoryInterface`, with app and server implementations and a test against real SQLite
- [x] 1.2 Add `calendar_cells.dart` in core: `CalendarMode`, `CalendarDay`, `CalendarCell`, `calendarCells`
- [x] 1.3 Test `calendarCells` for each scenario of "Calendar periods" and "Cell contents", a week in progress, a period without records, a clock change, and the "Average of a week with a gap" scenario
- [x] 1.4 Add `formatAmount` with tests for every "Number format" scenario and a negative sum

## 2. Mode state

- [x] 2.1 Add `CalendarModeCubit` in `lib/app/state/` with `weeks` as the default and provide it above the navigator

## 3. Form screen

- [x] 3.1 Turn `TrackingGapSheet` into `TrackingGapFormScreen`, update `tracking_gaps_screen.dart` and `days_screen.dart`
- [x] 3.2 Move `tracking_gap_sheet_test.dart` to the form screen

## 4. Calendar widgets

- [x] 4.1 Add the bar painter with the drawing rules of "Day bars", with a widget test for each day state
- [x] 4.2 Add the cell widget for compact use
- [x] 4.3 Move the drag devices of `HorizontalDragScrollArea` into a shared constant
- [x] 4.4 Add `CalendarWidget` with the lazy reversed list, reload on `HomeFetched` and the menu
- [x] 4.5 Add `CalendarCellSheet` with sums, macros, coverage, average, gaps, "Add gap" and "Show records"
- [x] 4.6 Add `CalendarScreen` with the day grid and the week and month lists

## 5. Tracking tab

- [x] 5.1 Replace `StatsWidget` with `CalendarWidget` in `tracking_tab.dart`
- [x] 5.2 Remove `stats_widget.dart`, `empty_days_row.dart`, `emptyDayCount`, `weeklyAverages` and its tests, keeping `weekOf`

## 6. Verification

- [x] 6.1 `cd packages/core && dart test`
- [x] 6.2 `cd packages/server && dart test` and `make test-server`
- [x] 6.3 `flutter test`, `flutter analyze` and `make arch`
- [x] 6.4 Run the `review-ui` skill on the changed widgets
- [ ] 6.5 Run the app and check all three modes, horizontal scrolling, the full screen, details and adding a gap on a narrow screen
