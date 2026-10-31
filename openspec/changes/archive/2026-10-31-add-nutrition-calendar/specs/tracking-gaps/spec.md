## MODIFIED Requirements

### Requirement: Tracking gap
A tracking gap SHALL be a closed period of a profile with a required start, a required
end and an optional free-text description. Gaps SHALL be added and edited on a form on
its own screen. Saving SHALL require the start to be before the end and the end to be no
later than the current time. Records inside a gap SHALL NOT be changed or removed.

#### Scenario: Evening gap
- **WHEN** the user saves a gap from 18:00 to 23:30 yesterday with no description
- **THEN** the gap is stored and all of yesterday's records are unchanged

#### Scenario: End in the future
- **WHEN** the user tries to save a gap that ends tomorrow
- **THEN** the gap is not saved and the form shows why

#### Scenario: End before start
- **WHEN** the user tries to save a gap whose end is before its start
- **THEN** the gap is not saved and the form shows why
