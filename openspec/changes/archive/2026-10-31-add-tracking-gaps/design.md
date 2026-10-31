## Context

`fetchDaysByProfile` groups by `record_day`, so a day without records does not exist in
`days30`, in `days_screen.dart` or in `CalorieRecommendationService`. A partial day is
a real row whose `valueSum - baseCalorieGoal` is negative, so it raises the
recommendation.

Sync facts this design relies on:

- `Syncer` iterates `SyncAdapterRegistry`, for both server and folder sync, so an older
  app build ignores a type it has not registered.
- `SyncV2Handler` stores entries of any `entity_type`; only `calorie_item` is
  materialized.
- `Syncer` always pushes `isDeleted: false`. Deletions only originate from the web
  client's `/api/records`, so an entity hard-deleted on the phone stays on the server
  and on other devices.

## Goals / Non-Goals

**Goals:**
- A gap can cover hours or days, and every statistic treats it the same way.
- One classification function shared by the app, the embedded server, the server and
  the LLM export.

**Non-Goals:**
- Open-ended gaps ("not counting now"): the user declined them.
- A separate marker for a confirmed zero day. A real fasting day stays `empty` and
  highlighted for now.
- A user-entered calorie estimate, or feeding an LLM's guess back into statistics.
- Web UI for gaps, and `≥`/`—` markers on the web home page.
- General phone-side deletion through sync.

## Decisions

### `TrackingGap` is an interval of instants

```
TrackingGap
  id, profileId
  startedAt, endedAt      required
  description?            optional, editable
  createdAt, updatedAt
  deletedAt?              soft delete
```

The domain and repository interface live in
`packages/core/lib/features/calorie_tracking/domain/`, the adapter in `.../sync/`, the
app repository in `lib/features/calorie_tracking/data/sqlite/`. Marking whole days is an
interval between local midnights.

Alternative: a flag on the day. Rejected, because it cannot express hours.

Validity: `startedAt < endedAt <= now`. Gaps describe the past only; a future end would
be an open gap by another name. The check runs when saving in the UI. Sync and
statistics do not reject a gap, because a pulled gap is already a fact.

Overlapping gaps are allowed, since two devices can create them independently, and
statistics treat gaps as a union of intervals.

### Soft delete

Deleting a gap sets `deletedAt` and `updatedAt`. It travels as an ordinary edit under
the existing last-write-wins rule, and every reader filters it out.

Alternative: push `isDeleted` entries from `Syncer`. Rejected for now, because phone
deletes do not propagate for any entity. That is a sync-wide change with its own
retention questions, and should not be bundled here.

### Day classification

`packages/core/.../domain/day_status.dart`:

```
enum DayStatus { tracked, empty, partial, unknown }

DayStat { DateTime day; double kcal; DayStatus status; }

List<DayStat> dayStats({
  days, gaps, firstRecordDay, from, to,
})
```

| Records | Overlaps a gap | Status | Counted in averages |
|---|---|---|---|
| yes | no | `tracked` | yes |
| no | no | `empty` | yes, as 0 kcal |
| yes | yes | `partial` | no |
| no | yes | `unknown` | no |

Overlap uses half-open intervals, so a gap ending exactly at midnight does not touch
the next day. Days before `firstRecordDay` are not produced, which keeps the rest of
history from being highlighted. Today is not produced as a past day. It is never
highlighted, and its overlap is handled by the indicators.

`firstRecordDay` comes from a new `fetchFirstRecordDay(profile)` on
`CalorieRecordRepositoryInterface`, because `days30` is limited to 30 rows.

`averageDailyKcal` from the previous change gains a `dayStats` based form: the sum of
`tracked` and `empty` days divided by their count, 0 when there are none. The worked
example: 4 days of 2000 kcal, 1 `empty`, 2 `unknown` gives 1600 kcal; marking the
`empty` day gives 2000 kcal.

### Recommendation differs from statistics on purpose

The caller passes `CalorieRecommendationService` only `tracked` days. `empty` days stay
out, as they do today, even though statistics count them as 0. With a 2000 kcal goal,
one forgotten day would otherwise be a -2000 kcal deviation and push the recommendation
towards `maxDailyAdjustment`. `partial` and `unknown` are excluded too.

The service's lookback counts rows, so excluded days let an older day in. Its weight
already depends on `daysAgo`, so it counts less.

### Partial indicators

Any gap overlapping an indicator's window shows the value as `≥ 1450` and hides the
`left`/`over` text, since the remainder is unknown. Today, 24h Rolling, Yesterday and
Period follow this rule. Yesterday shows `—` when its status is `unknown`.

### Weekly chart

`weeklyTotals` is replaced by per-week averages over counted days, excluding today. The
total is unfair to an unfinished week and to weeks with gaps; the average is
comparable and gives a single goal line at `caloriesLimitGoal`. A week with no counted
days shows a placeholder bar. Labels use short values and appear on every third bar,
because at 360 logical pixels a bar is about 20 pixels wide and `14.0k` is clipped.

### Finding and marking days

- `DaysScreen` shows the last 30 calendar days from `dayStats`, and `empty` rows are
  highlighted. Tapping one opens the gap sheet prefilled with that whole day.
- The Tracking tab shows a row with the count of `empty` days in the last 30 days when
  it is above 0; tapping opens `DaysScreen`.
- A new `TrackingGapsScreen`, reached from `DaysScreen`, lists gaps and handles adding,
  editing and deleting, in the manner of `WakingPeriodsScreen`.
- The sheet's description hint reads "Roughly what did you eat? How hungry were you?".

`HomeFetched` gains `trackingGaps` and `firstRecordDay`, so screens get them through the
existing bloc. `lib/features/calorie_tracking/ui/` holds the new widgets; `dashboard`
may depend on it.

### Server reads gaps from the sync log

`HomeHandler` decodes `tracking_gap` entries through a new
`SyncEntryRepository.findAllByUserAndType`, and skips entries with `deletedAt`. No new
table is added: nothing but the average needs gaps on the server, and a table would
need materialization and a startup backfill as well. If the web later edits gaps, a
table can be added then.

### LLM export

`LlmExportFormatter.format` gains `gaps` and uses `dayStats`. Explanations sit inside
each section, because a custom preamble replaces `defaultPreamble` entirely.

- A `partial` day's header gets `(incomplete: overlaps a tracking gap)`.
- `## Tracking gaps` lists gaps in time order, with descriptions on one line.
- `## Unconfirmed empty days` lists `empty` days, with consecutive days as a range.
  They count as 0 in the summary's average, but the section tells the LLM that the user
  may have forgotten to log, which fits the preamble's "unknown, not zero".
- `## Weekly summary` reports `N days counted`, the `partial`, `empty` and `unknown`
  counts, and the same average as the app.

## Risks / Trade-offs

- [Soft-deleted rows accumulate] → Very low volume for a hand-created entity.
- [A reader forgets the `deletedAt` filter] → `fetchByProfile` filters inside the
  repository; only `findAll` for sync returns deleted rows.
- [A real fasting day stays highlighted] → Accepted for now; a "confirmed 0 kcal" marker
  can be added later without changing the model.
- [Several phone profiles map to one server profile] → The server applies all of the
  user's gaps to its single profile, as it already does for records.
- [Descriptions are personal text in the synced folder and export file] → Accepted:
  reaching the LLM is the field's purpose.
- [The `sync` and `tracking-stats` deltas need their base specs] →
  `openspec/specs/sync/` is still untracked and must be committed; `tracking-stats`
  exists only after `fix-tracking-stats-numbers` is archived.

## Migration Plan

Migration v019 creates `tracking_gaps` with an index on `(profile_id, started_at)`, and
`V001InitialSchema` gets the same table, because a fresh install runs only that.
Older app builds ignore the new entity type, and older servers store it like any other.
Rollback leaves an unused table.
