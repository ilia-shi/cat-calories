# tracking-gaps Specification

## Purpose
TBD - created by archiving change add-tracking-gaps. Update Purpose after archive.
## Requirements
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

### Requirement: Gap editing
The user SHALL be able to list a profile's gaps and to change a gap's start, end and
description, or delete it. A deleted gap SHALL stop affecting statistics and exports
immediately.

#### Scenario: Description added later
- **WHEN** the user adds a description to an existing gap
- **THEN** the gap keeps its period and the description appears in the next LLM export

#### Scenario: Gap deleted
- **WHEN** the user deletes the gap covering an `unknown` day that has no records
- **THEN** that day becomes `empty`

### Requirement: Gap description hint
The description field SHALL be optional and SHALL show the hint "Roughly what did you
eat? How hungry were you?".

#### Scenario: Empty description
- **WHEN** the user leaves the description blank
- **THEN** the gap is saved without a description

### Requirement: Overlapping gaps
Gaps MAY overlap. Statistics SHALL treat a profile's gaps as the union of their
intervals.

#### Scenario: Same day marked on two devices
- **WHEN** two devices each create a gap for the same day and both sync
- **THEN** both gaps exist and the day's status is the same as with one gap

### Requirement: Gap deletion across devices
Deleting a gap SHALL mark it as deleted rather than remove its row, and the mark SHALL
replicate as an ordinary edit.

#### Scenario: Deleted on one device
- **WHEN** a gap is deleted on the phone and two devices then sync
- **THEN** the gap no longer affects statistics on the other device or on the server

