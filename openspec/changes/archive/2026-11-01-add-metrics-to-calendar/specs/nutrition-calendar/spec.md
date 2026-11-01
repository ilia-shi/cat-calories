## ADDED Requirements

### Requirement: Calendar content
The calendar SHALL show either food or one metric: steps, sleep or burned kcal. The
default SHALL be food. The choice SHALL be shared by the widget and the full screen and
SHALL last until the app is closed. Modes SHALL work the same for every content.

#### Scenario: Choosing a metric
- **WHEN** the user picks Steps in the widget's menu
- **THEN** the widget shows steps and its title reads `Steps · Weeks`

#### Scenario: Same choice in the full screen
- **WHEN** the user picks Sleep and opens the full screen
- **THEN** the full screen shows sleep

#### Scenario: New app run
- **WHEN** the user picks Steps and restarts the app
- **THEN** the widget shows food

#### Scenario: Metric without values
- **WHEN** the user picks a metric that has no values
- **THEN** the calendar says there are no values yet, and the menu stays available

### Requirement: Metric periods
Metric cells SHALL use the periods of food cells. They SHALL start at the period of the
metric's earliest value and end at the period containing today, including periods
without values.

#### Scenario: Month without values
- **WHEN** the user has steps in August and October but not in September
- **THEN** month mode shows a September cell with `—`

### Requirement: Metric cell value
A cell of steps or burned kcal SHALL show the sum over days with a value, today included.
A cell of sleep SHALL show the average per night over days with a value, today included.
Only days with a value SHALL count, and a saved 0 SHALL count as a value. A period
without values SHALL show `—`. Steps and kcal SHALL follow the calendar's number format.
Sleep in a cell SHALL show as hours and minutes, rounded to a whole minute.

#### Scenario: Week of steps
- **WHEN** a week has 8000, 9000 and 11000 steps on three days and no other values
- **THEN** its cell shows `28K`

#### Scenario: Week of sleep
- **WHEN** a week has 7 h and 8 h of sleep on two days and no other values
- **THEN** its cell shows `7h 30m`

#### Scenario: Saved zero
- **WHEN** a week has 0 and 8000 steps on two days
- **THEN** both days count as days with a value

### Requirement: Metric bars
A metric cell SHALL show one bar per day of its period. The full height SHALL be fixed per
metric: 20000 steps, 12 hours of sleep and 5000 burned kcal. A day above the full height
SHALL be drawn at full height in the normal colour. Today SHALL be lighter than other
days, a day that has not come SHALL be a dot, and a day without a value SHALL have no bar
and no highlight. Metric bars SHALL have no goal line.

#### Scenario: Comparing weeks
- **WHEN** Monday of one week has 12000 steps and Monday of the previous week has 6000
- **THEN** the first bar of the newer week is twice as tall

#### Scenario: Day without a value
- **WHEN** a past day has no sleep value
- **THEN** its slot is empty and not tinted

### Requirement: Metric details
Tapping a metric cell SHALL open details with the period and one row per metric that has
a value in the period. A row of steps or burned kcal in week or month mode SHALL show the
sum, the average per day over days with a value without today, and how many days that
is. A row of sleep in week or month mode SHALL show the average per night and how many
nights that is. In day mode a row SHALL show the value and its note. The average SHALL be
a whole number, and its part SHALL be omitted when no day counts.

#### Scenario: Week of steps
- **WHEN** a finished week has 8000, 9000 and 10000 steps on three days
- **THEN** the steps row shows `27K`, `9000` per day and `3 of 7 days`

#### Scenario: Only today
- **WHEN** the current week has steps for today only
- **THEN** the steps row shows the sum and no average

#### Scenario: Note
- **WHEN** a day's sleep value has the note "Woke up twice"
- **THEN** the details of that day show the note

### Requirement: Metrics in food details
Food cell details SHALL also show the metric rows of the period. They SHALL show no metric
row for a metric without a value in the period.

#### Scenario: Week with sleep only
- **WHEN** the user opens a food week that has sleep values and no steps
- **THEN** the details have a sleep row and no steps row

### Requirement: Calendar follows metric changes
The calendar SHALL show the changed values after the user leaves the Metrics screen. It
SHALL NOT reload when nothing changed there.

#### Scenario: Saving a value
- **WHEN** the user saves steps on the Metrics screen and returns to the Tracking tab
- **THEN** the calendar shows the new value

## MODIFIED Requirements

### Requirement: Calendar widget
The Tracking tab SHALL show a calendar widget with one cell per period, scrolling
horizontally with the current period at the right edge. The widget SHALL have one menu
in its top right corner with the modes days, weeks and months, the contents food, steps,
sleep and burned, "Open full screen" and "Add gap".

#### Scenario: Scrolling back
- **WHEN** the user drags the widget to the right
- **THEN** older periods appear and the tab does not switch

#### Scenario: Opening the full screen
- **WHEN** the user picks "Open full screen" in the menu
- **THEN** the full-screen calendar opens in the same mode

#### Scenario: Adding a gap from the menu
- **WHEN** the user picks "Add gap" in the menu
- **THEN** the gap form screen opens

### Requirement: Full-screen calendar
The full-screen calendar SHALL offer the same modes and contents. In day mode it SHALL
show a Monday-to-Sunday grid per month. In week and month modes it SHALL show a vertical
list.

#### Scenario: Day mode
- **WHEN** the user opens the full screen in day mode
- **THEN** each month appears as a grid with seven columns

#### Scenario: Metric in day mode
- **WHEN** the user picks Steps in the full screen in day mode
- **THEN** each month appears as a grid of steps with seven columns
