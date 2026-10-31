## Why

Several numbers on the Tracking tab are wrong, and the same seven-day average is
computed three different ways, so the app, the embedded server and the web client can
disagree. These fixes need no new data and should land before tracking gaps build on
the same statistics.

## What Changes

- The macros on the "24h Rolling" card cover the last 24 hours instead of the three
  calendar days held in `rollingWindowCalorieItems`.
- One seven-day average in `packages/core`, used by `tracking_tab.dart`,
  `home_controller.dart` and the server's `home_handler.dart`. It covers the 7 full
  calendar days before today and divides by the number of days in the window, so a
  day without records counts as 0 kcal. Days before the profile's first eaten record
  are not part of the window.
- The `+Nh` part of the Today card title is computed from the current time, not from
  `_baseTime`, so it no longer goes stale or negative.
- The JSON export writes `calorie_content` from `caloriesPer100g`, not `carbsPer100g`.

## Capabilities

### New Capabilities

- `tracking-stats`: what the indicators on the Tracking tab and `/api/home` report.
- `data-export`: what the data exports contain.

### Modified Capabilities

None.

## Impact

- `packages/core/lib/features/calorie_tracking/domain/`: new pure functions and tests.
- `lib/features/dashboard/ui/tabs/tracking_tab.dart`,
  `lib/features/embedded_server/controllers/home_controller.dart`,
  `lib/features/calorie_tracking/calorie_exporter.dart`.
- `packages/server/lib/handler/home_handler.dart`, `packages/server/bin/server.dart`.
- `/api/home` keeps its JSON shape; the value of `avg_7_days` changes.
- Users with skipped days will see a lower `7-Day Avg` than before. Marking those days
  as not tracked arrives with `add-tracking-gaps`, so the two changes should ship
  together.
