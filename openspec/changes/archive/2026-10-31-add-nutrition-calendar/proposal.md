## Why

The Tracking tab shows only weekly calories, macros per day or week appear nowhere, and
the highlight for days without records lives on the legacy Days screen. The user wants
one place to compare days, weeks and months, see gaps, and mark them.

## What Changes

- New calendar widget on the Tracking tab with horizontal scrolling and day, week and
  month modes. Each cell shows the calorie sum, macros, gap state and one small bar per
  day.
- A menu in the widget's top right corner: mode, open full screen, add gap. The mode
  lasts until the app is closed.
- A full-screen calendar with the same modes.
- Tapping a cell opens details: sums, macros, average per day, gaps and their
  descriptions, and an action to add a gap for that period.
- No decimals anywhere in the calendar. Weeks and months shorten values from 1000 up:
  `45320` becomes `45.3K`.
- **BREAKING** The weekly chart (`StatsWidget`) and `EmptyDaysRow` are removed from the
  Tracking tab. `weeklyAverages` goes with them.
- Adding or editing a gap moves from `TrackingGapSheet` to a form on its own screen.

## Capabilities

### New Capabilities

- `nutrition-calendar`: the widget, the full screen, cells, bars, number formats and
  details.

### Modified Capabilities

- `tracking-stats`: the "Weekly chart" requirement is removed.
- `day-status`: empty days are highlighted in the calendar, not through `EmptyDaysRow`.
- `tracking-gaps`: gaps are edited on a form screen.

## Impact

- `packages/core`: new calendar domain and a full-history query on
  `CalorieRecordRepositoryInterface`, implemented in the app and server repositories.
- `lib/features/calorie_tracking/ui/`: calendar widgets, details, form screen.
- `lib/features/dashboard/ui/`: `tracking_tab.dart`, removal of `stats_widget.dart`.
- `lib/app/`: a cubit holding the mode, provided above the navigator.
- No migration, no API change, no sync change. `DaysScreen` stays as it is, apart from
  opening the form screen.
- Builds on `add-tracking-gaps`, whose task 8.6 (running the app) is still open.
