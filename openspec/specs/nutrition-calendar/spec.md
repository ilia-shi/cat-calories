# nutrition-calendar Specification

## Purpose
TBD - created by archiving change add-nutrition-calendar. Update Purpose after archive.
## Requirements
### Requirement: Calendar widget
The Tracking tab SHALL show a calendar widget with one cell per period, scrolling
horizontally with the current period at the right edge. The widget SHALL have one menu
in its top right corner with the modes days, weeks and months, "Open full screen" and
"Add gap".

#### Scenario: Scrolling back
- **WHEN** the user drags the widget to the right
- **THEN** older periods appear and the tab does not switch

#### Scenario: Opening the full screen
- **WHEN** the user picks "Open full screen" in the menu
- **THEN** the full-screen calendar opens in the same mode

#### Scenario: Adding a gap from the menu
- **WHEN** the user picks "Add gap" in the menu
- **THEN** the gap form screen opens

### Requirement: Calendar mode
The default mode SHALL be weeks. The chosen mode SHALL be shared by the widget and the
full screen and SHALL last until the app is closed.

#### Scenario: Mode survives a refresh
- **WHEN** the user picks months and pulls to refresh
- **THEN** the widget is still in months

#### Scenario: New app run
- **WHEN** the user picks months and restarts the app
- **THEN** the widget is in weeks

### Requirement: Calendar periods
Day cells SHALL cover one calendar day, week cells a Monday-to-Sunday week, and month
cells a calendar month. Cells SHALL start at the period of the earliest eaten record and
end at the period containing today, including periods without records.

#### Scenario: Month without records
- **WHEN** the user logged in August and October but not in September
- **THEN** month mode shows a cell for September

### Requirement: Cell contents
A cell SHALL show the sum of calories and of protein, fat and carbs over all days of its
period, today included, and the gap state of the period. The kcal value SHALL be
prefixed with `≥` when a gap overlaps the period. A macro SHALL be prefixed with `≥` when
some eaten records of the period lack macros, and SHALL show `—` when none have them. A
day cell with status `unknown` SHALL show `—` as its kcal value.

#### Scenario: Week sum
- **WHEN** a finished week has daily totals of 2510, 2400, 2200, 3400, 2500, 2500 and 2200 kcal
- **THEN** its cell shows `17.7K`

#### Scenario: Period with a gap
- **WHEN** a week has 6800 kcal of records and a gap on one day
- **THEN** its cell shows `≥ 6.8K`

#### Scenario: Some records without macros
- **WHEN** a day has 96 g of protein and one eaten record has no macros
- **THEN** its cell shows `≥ 96` for protein

### Requirement: Number format
The calendar SHALL show no decimals, with one exception: in week and month modes a value
of 1000 or more in magnitude SHALL be shown in thousands with at most one decimal and
the suffix `K`. Day mode and the average per day SHALL always be whole numbers.

#### Scenario: Large week value
- **WHEN** a value in week mode is 45320
- **THEN** it is shown as `45.3K`

#### Scenario: Whole thousands
- **WHEN** a value in month mode is 45000
- **THEN** it is shown as `45K`

#### Scenario: Value below a thousand
- **WHEN** a value in week mode is 785.4
- **THEN** it is shown as `785`

#### Scenario: Day mode
- **WHEN** a value in day mode is 1873.46
- **THEN** it is shown as `1873`

### Requirement: Day bars
A cell SHALL show one bar without a number per day of its period: 1 in day mode, 7 in
week mode and one per day of the month in month mode. The full height of a bar SHALL be
twice the profile's daily goal in every cell, and a line SHALL mark the goal. A day above
the full height SHALL be drawn at full height in red. Today SHALL be lighter than other
days, a `partial` day muted at its kcal, an `unknown` day muted at full height, an
`empty` day SHALL have no bar and a tinted slot, and a day that has not come SHALL be a
dot.

#### Scenario: Comparing weeks
- **WHEN** Monday of one week has 3000 kcal and Monday of the previous week has 2510 kcal
- **THEN** the first bar of the newer week is taller than that of the older week

#### Scenario: Week in progress
- **WHEN** it is Wednesday
- **THEN** the week's cell has bars for Monday and Tuesday, a lighter bar for today, and four dots

#### Scenario: Day far above the goal
- **WHEN** the goal is 2000 kcal and a day has 5000 kcal
- **THEN** its bar has full height and is red

### Requirement: Full-screen calendar
The full-screen calendar SHALL offer the same modes. In day mode it SHALL show a
Monday-to-Sunday grid per month. In week and month modes it SHALL show a vertical list.

#### Scenario: Day mode
- **WHEN** the user opens the full screen in day mode
- **THEN** each month appears as a grid with seven columns

### Requirement: Cell details
Tapping a cell SHALL open its details: period, calories, macros, how many records have
macros, and the gaps overlapping the period with their descriptions. Week and month
details SHALL also show the average per day over the period's counted days and how many
days that is, by the rule of the seven-day average. Details SHALL offer "Add gap",
prefilled with the period and cut at the current moment, and in day mode "Show records".

#### Scenario: Average of a week with a gap
- **WHEN** a finished week has 5 `tracked` days totalling 9335 kcal, 1 `partial` day and 1 `unknown` day
- **THEN** the details show `1867` per day over 5 of 7 days

#### Scenario: Gap in the details
- **WHEN** a gap with the description "Dinner out" overlaps the period
- **THEN** the details show that description, and tapping it opens the gap in the form

#### Scenario: Adding a gap to the current week
- **WHEN** the user taps "Add gap" in the details of the current week
- **THEN** the form opens from the week's Monday to the current moment

