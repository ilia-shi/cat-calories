## ADDED Requirements

### Requirement: Fixed metric list
The system SHALL offer the metrics steps, sleep and burned kcal, each holding at most one
value per profile, calendar day and source. Values entered by the user SHALL use the
source `manual`.

#### Scenario: Entering a value twice
- **WHEN** the user saves 9000 steps for a day and then saves 9500 steps for the same day
- **THEN** the day holds one steps value, 9500

### Requirement: Absent value is unknown
The system SHALL treat a day without a value as unknown, never as 0, and SHALL show it as
a dash without a highlight or a prompt. A saved 0 SHALL stay a value.

#### Scenario: Day without steps
- **WHEN** a day has no steps value
- **THEN** the steps cell of that day shows a dash

#### Scenario: Saved zero
- **WHEN** the user saves 0 steps for a day
- **THEN** the steps cell of that day shows 0

### Requirement: Entering a value
The system SHALL let the user enter a value for today or any past day from the Metrics
screen, with an optional note. It SHALL reject a future day, a negative value and sleep
above 24 hours. Steps, sleep minutes and burned kcal SHALL be stored as whole numbers.

#### Scenario: Value without a note
- **WHEN** the user enters 2400 for burned kcal and leaves the note empty
- **THEN** the value is saved

#### Scenario: Sleep is typed in hours
- **WHEN** the user enters 7.5 for sleep
- **THEN** the system stores 450 minutes and shows `7 h 30 min`

#### Scenario: Too much sleep
- **WHEN** the user enters 25 for sleep
- **THEN** the system does not save the value and states the reason

### Requirement: Sleep belongs to the day of waking up
The system SHALL state in the sleep input that the value belongs to the day the user woke
up.

#### Scenario: Opening the sleep input
- **WHEN** the user opens the sleep input for a day
- **THEN** the sheet says the value is for the night that ended on that day

### Requirement: Editing and clearing a value
The system SHALL let the user change or clear an existing value and its note. Clearing
SHALL return the day to the absent state, and a later entry for that day SHALL be saved
as a value again.

#### Scenario: Clearing a value
- **WHEN** the user clears the steps value of a day
- **THEN** the steps cell of that day shows a dash

#### Scenario: Entering after clearing
- **WHEN** the user clears a value and then enters a new one for the same metric and day
- **THEN** the new value is shown and syncs like any other change

### Requirement: Metrics screen
The system SHALL open a Metrics screen from the app menu that lists one row per calendar
day, newest first, from today back to the older of 30 days ago and the oldest entry. Each
row SHALL show one cell per metric. The system SHALL offer a way to reach any older day.

#### Scenario: Reaching an older day
- **WHEN** the user picks a date 90 days ago
- **THEN** the list extends to that date and the user can enter a value for it

#### Scenario: Old entry
- **WHEN** the oldest entry is 60 days old
- **THEN** the list reaches back 60 days

### Requirement: Burned kcal does not affect food
The system SHALL NOT use burned kcal in the calorie budget, the recommended calories or
any food statistic.

#### Scenario: High burned kcal
- **WHEN** the user saves 3000 burned kcal for today
- **THEN** remaining calories and recommended calories do not change

### Requirement: Works without metrics
The system SHALL keep every existing screen unchanged when no metric has been entered.

#### Scenario: User never opens Metrics
- **WHEN** no metric value exists
- **THEN** the home screen and the calendar look and work as before
