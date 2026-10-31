## Context

The Tracking tab builds its indicators in `tracking_tab.dart`. Four defects were found
by reading the code:

- `MacroData.fromCalorieItems(state.rollingWindowCalorieItems)` has no 24-hour filter,
  and `_fetchRollingWindowItems` loads today, yesterday and the day before.
- `_calculateAverageLast7Days` uses `dayDate.isAfter(sevenDaysAgo)`. Day keys are local
  midnights, so the seventh day is excluded and only 6 days are read. It then divides
  by the number of days that have records.
- `IndicatorData.now` is `_baseTime`, set in `initState` and on pull-to-refresh only.
  The tab is kept alive, so the `+Nh` title drifts.
- `calorie_exporter.dart:48` fills `calorie_content` from `carbsPer100g`.

The average also exists in `home_controller.dart`, with the same defects, and in the
server's `home_handler.dart`, where the window includes today and rows that were never
eaten.

## Goals / Non-Goals

**Goals:**
- One tested definition of the seven-day average, shared by all three call sites.
- Correct values with no schema or API shape change.

**Non-Goals:**
- Tracking gaps and day statuses (`add-tracking-gaps`).
- Removing the unused `_hoursOffset` simulation code.
- Redesigning the weekly chart.

## Decisions

### Pure functions in `packages/core`

`averageDailyKcal(List<DayResult> days, {required DateTime now, int windowDays = 7})`
goes into `domain/average_daily_kcal.dart`. `eatenInLast24h(records, asOf)` goes next
to it in `domain/calorie_record` helpers. Core is the only layer the app and the server
share, and it is where tests already live; `lib/` has no widget tests.

Alternative: keep the fix inside each caller. Rejected, because three copies are how
the definitions diverged.

### Window rule

The window is the `windowDays` calendar days ending yesterday, built from calendar
fields rather than by subtracting a `Duration`, as `weekOf` does, so a DST switch
cannot move a boundary. Today is excluded because it is unfinished.

The start of the window is clipped to the earliest day in `days`. Without the clip a
new user with 3 days of history would be divided by 7. Callers pass at least 30 day
rows, so the earliest row is older than the window unless the history really is that
short. With no days the result is 0.

The fallback to `_tracker.getAverageDaily` is removed: it only reads the rolling
window, which spans 3 days, and then divides by 7.

### 24-hour macros

`eatenInLast24h` uses `eatenAt ?? createdAt` and the same window as
`RollingCalorieTracker.consumedInLast24h`: strictly after `asOf - 24h`, not after
`asOf`. Calories and macros on the card therefore cover identical records.

### Today title

`IndicatorData.now` receives `_currentTime`. The existing 30-second timer already
rebuilds the tab, so no new timer is needed.

### Server average

`HomeHandler` receives the server's calorie record repository and calls
`fetchDaysByProfile(profile, 30)`, then `averageDailyKcal`. This also drops never-eaten
rows from the average, matching the app.

## Risks / Trade-offs

- [The average falls for users who skip days] → Expected under the agreed rule; the
  way to mark those days comes with `add-tracking-gaps`.
- [The server's day boundaries use the server's time zone] → Existing behaviour of
  `/api/home`, not changed here.
