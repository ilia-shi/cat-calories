## Context

`fetchDaysByProfile` sums only calories and is limited to a row count. `MacroData` shows
how the app already treats missing macros: a record without them is not 0 g. The home
`TabBarView` uses `NeverScrollableScrollPhysics`, so a horizontal list cannot conflict
with a tab swipe. `dayStats` and `averageOfCountedDays` already define day statuses and
the average rule. `HorizontalDragScrollArea` is not lazy, so it cannot host a long list.

## Goals / Non-Goals

**Goals:**
- One cell model for the compact and full views, built by pure functions in core.
- Bars comparable between any two cells.

**Non-Goals:**
- Calendar in the web client.
- Removing `DaysScreen` or the "Not tracked periods" menu entry.
- Persisting the mode across app restarts.
- A historic goal: bars use the profile's current goal for all of history.

## Decisions

### Full-history day query

`fetchDayNutrition(profile)` returns one `DayNutrition` per `record_day` with eaten
records: kcal, protein, fat, carbs, `recordCount` and `recordsWithMacros`. It has no
limit: one row per day is about 1100 rows for 3 years, grouped over an indexed column.

Alternative: extend `DayResult` and its callers. Rejected, because `DayResult` feeds the
recommendation and the export, and neither needs macros.

The method joins `CalorieRecordRepositoryInterface`, so the server implements it too.

### Cells are built in core

`calendar_cells.dart`:

```
enum CalendarMode { days, weeks, months }

CalendarDay { day, DayStatus? status, DayNutrition? nutrition, isToday }
            status is null for a day that has not come yet

CalendarCell { start, end, mode, days,
               kcal, protein, fat, carbs,
               hasGap, macrosIncomplete, averageKcal, countedDays, periodDays }

List<CalendarCell> calendarCells(nutrition, gaps, firstRecordDay, mode, now)
```

Cells run from the first record's period up to the period containing today, oldest
first, so an empty stretch of history still has cells. The status of each day comes
from `dayStats`, run up to tomorrow so today is included. Today is never highlighted.

`kcal` and the macro fields are sums over all days of the period, today included.
`averageKcal` follows `averageOfCountedDays` over days before today, so it matches
`7-Day Avg`. A cell's sum can therefore cover days its average does not.

### Number format

`formatAmount(value, mode)` in core. Decimals never appear, with one exception: in week
and month modes a magnitude of 1000 or more becomes thousands with at most one decimal,
dropping `.0`. `45320` gives `45.3K`, `45000` gives `45K`. Below 1000, and always in
day mode, the value is a whole number. The average per day is always a whole number.
Negative sums keep their sign, since records may have negative values.

A kcal value is prefixed with `≥` when `hasGap` is set; a macro with `≥` when
`macrosIncomplete` is set. An `unknown` day shows `—`. A cell with no macro data shows
`—` for each macro.

### Bars

One `CustomPaint` per cell draws all its bars and the goal line, which stays cheap at 31
bars. Day mode has 1 bar, week mode 7, month mode one per day of the month.

The full height of a bar is always twice the profile's daily goal, so the goal line sits
at half height in every cell and bars from different cells compare directly. A taller
day is clipped to full height and drawn in red. Scaling to the largest day was rejected:
one 6000 kcal day would flatten the whole history.

| Day | Drawn as |
|---|---|
| `tracked` | primary colour |
| today | lighter primary |
| `empty` | no bar, tinted slot |
| `partial` | muted bar at its kcal |
| `unknown` | muted bar at full height |
| not yet come | a dot |

Hatching is not used: it cannot be read on a bar about 6 pixels wide.

### Compact widget

`CalendarWidget` replaces `StatsWidget` in `TrackingTab`, and reloads on `HomeFetched` in
the same way. A `ListView.builder` with `reverse: true` keeps today at the right and
builds cells lazily. Cell width is 56 logical pixels for days and weeks, about 6 weeks on
a 360-wide phone, and 96 for months. Mouse dragging uses the drag devices from
`HorizontalDragScrollArea`, moved into the shared constant `allDragDevices`.

The menu is one `PopupMenuButton`; there is no separate mode icon.

### Mode state

`CalendarModeCubit` in `lib/app/state/`, provided above the navigator, default `weeks`.
Widget state would not do: `TrackingTab` replaces its tree on `HomeFetchingInProgress`,
and the full screen must share the mode.

### Full screen

`CalendarScreen` reuses the cell content:

- Days: months stacked vertically, each a Monday-to-Sunday grid. A cell is about 48
  logical pixels wide, so it shows kcal and three macro numbers without letters at font
  size 9 to 10, coloured as `MacroBadge`.
- Weeks and months: a vertical list of wide rows.

### Details

`CalendarCellSheet` shows the period, sum, macros and macro coverage, and the average
with its day count for weeks and months, such as `1867 per day, 5 of 7 days`. It lists
overlapping gaps with their descriptions, each opening the form. Actions: "Add gap",
prefilled with the cell's period cut at the current moment, and in day mode "Show
records", which opens `DayCaloriesPage`.

### Form screen

`TrackingGapFormScreen` replaces `TrackingGapSheet`, keeping its fields, hint and
`trackingGapError` check. Its `onSave` callback stays so the existing tests can move.

## Risks / Trade-offs

- [Fewer periods fit than the 12 bars of the old chart] → A narrow cell shows about 6
  weeks; the rest is a scroll away.
- [The grid in full day mode is dense] → Accepted by design; details are one tap away.
- [Old days are judged against the current goal] → A goal change shifts how history
  reads. Accepted.
- [Sum and average of one cell cover different days] → The details state the day count.
- [Reloading the full history on every `HomeFetched`] → A single grouped query. If it
  shows up as slow, cache it and reload only changed days.
