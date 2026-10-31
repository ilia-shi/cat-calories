## MODIFIED Requirements

### Requirement: Seven-day average
The seven-day average SHALL be the sum of eaten calories of the `tracked` and `empty`
days among the 7 calendar days before today, divided by the number of those days. Today
SHALL NOT be included. `partial` and `unknown` days SHALL NOT be included. An `empty`
day SHALL count as 0 kcal. With no such days the average SHALL be 0. The Tracking tab's
`7-Day Avg`, the embedded server and the server's `/api/home` `avg_7_days` SHALL all use
this definition.

#### Scenario: Mixed week
- **WHEN** the 7 days before today are 4 `tracked` days of 2000 kcal, 1 `empty` day and 2 `unknown` days
- **THEN** the average is 1600 kcal

#### Scenario: Empty day marked as a gap
- **WHEN** the `empty` day in that week becomes `unknown`
- **THEN** the average is 2000 kcal

#### Scenario: Partial day is skipped
- **WHEN** a `partial` day with 500 kcal is one of the 7 days
- **THEN** its calories and the day itself are left out of the average

#### Scenario: Short history
- **WHEN** the earliest eaten record is 3 days ago and each of the last 3 days has 2000 kcal
- **THEN** the average is 2000 kcal

#### Scenario: Today is excluded
- **WHEN** 5000 kcal were eaten today
- **THEN** the average does not change

#### Scenario: All implementations agree
- **WHEN** the phone and the server hold the same records and gaps and use the same time zone
- **THEN** `7-Day Avg` on the Tracking tab and `avg_7_days` from `/api/home` are equal

## ADDED Requirements

### Requirement: Indicators during a gap
An indicator SHALL show its value as `≥` followed by the value when a gap overlaps the
window of that indicator. This SHALL apply to 24h Rolling, Today, Yesterday and Period.
The 24h Rolling and Today cards SHALL hide their `left` and `over` text in that case.
Yesterday SHALL show `—` when its status is `unknown`.

#### Scenario: Gap inside the rolling window
- **WHEN** a gap ended 5 hours ago and 1450 kcal are logged in the last 24 hours
- **THEN** the 24h Rolling card shows `≥ 1450` and no remaining calories

#### Scenario: No gap in the window
- **WHEN** the last gap ended 2 days ago
- **THEN** the 24h Rolling card shows its value and remaining calories as usual

### Requirement: Density scale during a gap
The 24h density scale SHALL show a bucket that overlaps a gap as not tracked, visually
distinct from a bucket with no calories.

#### Scenario: Hour inside a gap
- **WHEN** a gap covers the bucket from 3 to 2 hours ago
- **THEN** that bucket is hatched and its tooltip says it was not tracked

### Requirement: Weekly chart
The weekly chart on the Tracking tab SHALL show, for each of the last 12 Monday-to-Sunday
weeks, the average kcal per day over that week's `tracked` and `empty` days before today,
with a line at the profile's daily goal. A week with no such days SHALL be shown as having
no data, not as 0.

#### Scenario: Week in progress
- **WHEN** it is Wednesday and Monday and Tuesday have 2000 kcal each
- **THEN** the current week's bar is 2000 kcal, the same scale as a finished week

#### Scenario: Week fully inside a gap
- **WHEN** every day of a week is `unknown`
- **THEN** that week shows a no-data placeholder
