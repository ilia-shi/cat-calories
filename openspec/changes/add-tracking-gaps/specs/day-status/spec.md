## ADDED Requirements

### Requirement: Day status
Each past day from the day of the profile's earliest eaten record up to yesterday SHALL
have exactly one status:
- `tracked`: the day has eaten records and overlaps no gap;
- `empty`: the day has no eaten records and overlaps no gap;
- `partial`: the day has eaten records and overlaps a gap;
- `unknown`: the day has no eaten records and overlaps a gap.

Overlap SHALL use half-open intervals, and any overlap, however short, SHALL count.

#### Scenario: Short gap on a logged day
- **WHEN** a day has records and a 30-minute gap
- **THEN** its status is `partial`

#### Scenario: Gap ending at midnight
- **WHEN** a gap ends exactly at 00:00 on a day with records and no other gap
- **THEN** that day's status is `tracked`

#### Scenario: Day before the first record
- **WHEN** a day is earlier than the profile's earliest eaten record
- **THEN** the day has no status and is not shown

### Requirement: Full calendar
Day lists SHALL include every day that has a status, including days without records.

#### Scenario: Skipped day in the list
- **WHEN** the user logged on Monday and Wednesday but not on Tuesday
- **THEN** `DaysScreen` shows a row for Tuesday

### Requirement: Day value display
A day SHALL be displayed by status: `tracked` as its total, `empty` as `0`, `partial`
as `≥` followed by its total, and `unknown` as `—`.

#### Scenario: Partial day
- **WHEN** a `partial` day has 950 kcal of records
- **THEN** it is shown as `≥ 950`

#### Scenario: Unknown day
- **WHEN** a day's status is `unknown`
- **THEN** it is shown as `—`, not as `0`

### Requirement: Empty day highlight
`empty` days SHALL be highlighted in `DaysScreen`, and tapping one SHALL open the gap
sheet prefilled with that whole day. The Tracking tab SHALL show the number of `empty`
days in the last 30 days when there are any, and tapping it SHALL open `DaysScreen`.
Today SHALL NOT be highlighted.

#### Scenario: Marking an empty day
- **WHEN** the user taps a highlighted day and saves the prefilled gap
- **THEN** the day's status becomes `unknown` and its highlight disappears

#### Scenario: No records yet today
- **WHEN** nothing has been logged today
- **THEN** today is not highlighted and is not counted on the Tracking tab

### Requirement: Recommendation uses tracked days only
`CalorieRecommendationService` SHALL receive only `tracked` days, so `empty`, `partial`
and `unknown` days do not change the recommendation.

#### Scenario: Forgotten day
- **WHEN** yesterday has no records and no gap
- **THEN** the recommendation for today is the same as if yesterday were not in the history

#### Scenario: Partial day
- **WHEN** yesterday has 500 kcal of records and a gap
- **THEN** yesterday does not raise the recommendation for today
