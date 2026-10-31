## MODIFIED Requirements

### Requirement: Empty day highlight
`empty` days SHALL be highlighted in `DaysScreen` and in the calendar. Tapping one in
`DaysScreen` SHALL open the gap form prefilled with that whole day. Today SHALL NOT be
highlighted.

#### Scenario: Marking an empty day
- **WHEN** the user taps a highlighted day in `DaysScreen` and saves the prefilled gap
- **THEN** the day's status becomes `unknown` and its highlight disappears

#### Scenario: No records yet today
- **WHEN** nothing has been logged today
- **THEN** today is not highlighted

#### Scenario: Empty day in the calendar
- **WHEN** a past day has no records and no gap
- **THEN** its slot in the calendar is tinted
