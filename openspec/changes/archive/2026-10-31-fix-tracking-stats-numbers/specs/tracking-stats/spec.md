## ADDED Requirements

### Requirement: Rolling 24h macros
The macros on the "24h Rolling" card SHALL be summed from the same records as its
calorie value: eaten records whose `eatenAt`, or `createdAt` when `eatenAt` is absent,
is later than 24 hours ago and not later than now.

#### Scenario: Meal older than 24 hours
- **WHEN** a record with 30 g of protein was eaten 30 hours ago
- **THEN** those 30 g are not included in the card's protein value

#### Scenario: Meal inside the window
- **WHEN** a record with 30 g of protein was eaten 3 hours ago
- **THEN** those 30 g are included in the card's protein value

### Requirement: Seven-day average
The seven-day average SHALL be the sum of eaten calories over the 7 calendar days
before today, divided by the number of those days on or after the day of the earliest
eaten record. Today SHALL NOT be included. A day without records inside the window
SHALL count as 0 kcal. With no eaten records before today the average SHALL be 0. The
Tracking tab's `7-Day Avg`, the embedded server and the server's `/api/home`
`avg_7_days` SHALL all use this definition.

#### Scenario: Seventh day is included
- **WHEN** today is 2026-10-10 and the only records are 1400 kcal on 2026-10-03 and 1400 kcal on 2026-10-09, with earlier history on 2026-09-20
- **THEN** the average is 400 kcal

#### Scenario: Skipped day counts as zero
- **WHEN** four of the 7 days before today have 2000 kcal each, the other three have no records and there is older history
- **THEN** the average is 1143 kcal after rounding to a whole number

#### Scenario: Short history
- **WHEN** the earliest eaten record is 3 days ago and each of the last 3 days has 2000 kcal
- **THEN** the average is 2000 kcal

#### Scenario: Today is excluded
- **WHEN** 5000 kcal were eaten today
- **THEN** the average does not change

#### Scenario: All implementations agree
- **WHEN** the phone and the server hold the same records and use the same time zone
- **THEN** `7-Day Avg` on the Tracking tab and `avg_7_days` from `/api/home` are equal

### Requirement: Today card elapsed hours
The `+Nh` part of the Today card title SHALL be the whole hours between the first
meal eaten today and the current time, and SHALL stay correct while the tab remains
open.

#### Scenario: Tab kept open for hours
- **WHEN** the app was opened at 08:00, the first meal was eaten at 09:00, the last at 12:00, and the time is now 15:00 without a refresh
- **THEN** the title shows `09:00 - 12:00 +6h`

#### Scenario: Meals eaten after the app was opened
- **WHEN** the app was opened at 08:00 and all of today's meals were eaten later
- **THEN** the title does not show a negative number of hours
