# data-export Specification

## Purpose
TBD - created by archiving change fix-tracking-stats-numbers. Update Purpose after archive.
## Requirements
### Requirement: Product calories in the JSON export
The JSON export SHALL write each product's `calorie_content` from the product's
calories per 100 g.

#### Scenario: Product with different calories and carbs
- **WHEN** a product has 250 kcal and 40 g of carbs per 100 g
- **THEN** its exported `calorie_content` is 250 and its `carbohydrates` is 40

### Requirement: Tracking gaps in the LLM export
The LLM export SHALL contain a `## Tracking gaps` section when the profile has gaps. The
section SHALL explain, independently of the preamble, that logging was incomplete and
that descriptions are the user's rough recollection. Each gap SHALL be listed once, in
time order, with its period and description on one line. Deleted gaps SHALL be left out.

#### Scenario: Multi-day gap with no records
- **WHEN** a 5-day gap has a description and no records
- **THEN** the section lists one line with the period and the description

#### Scenario: Custom preamble
- **WHEN** the user has replaced the default preamble
- **THEN** the section still contains its explanation

#### Scenario: No gaps
- **WHEN** the profile has no gaps
- **THEN** the export has no `## Tracking gaps` section

### Requirement: Partial days in the LLM export
The header of a `partial` day SHALL state that the day is incomplete.

#### Scenario: Day overlapping a gap
- **WHEN** 2026-10-20 has 950 kcal of records and overlaps a gap
- **THEN** its header reads `## 2026-10-20 — total 950 kcal (incomplete: overlaps a tracking gap)`, with any macro and cost parts in their usual place

### Requirement: Empty days in the LLM export
The LLM export SHALL contain a `## Unconfirmed empty days` section listing `empty` days,
with consecutive days as one range, and stating that the user may have forgotten to log.

#### Scenario: Two consecutive empty days
- **WHEN** 2026-10-17 and 2026-10-18 are `empty`
- **THEN** the section lists one range from 2026-10-17 to 2026-10-18

### Requirement: Weekly summary by status
Each line of the LLM export's weekly summary SHALL report the number of counted days, the
numbers of `partial`, `empty` and `unknown` days when above zero, and the average kcal per
day by the same rule as the app. A week with only `unknown` days SHALL be listed without
an average.

#### Scenario: Week with a partial day
- **WHEN** a week has 5 `tracked` days, 1 `partial` and 1 `empty`
- **THEN** its line reports 6 days counted, 1 partial, 1 empty and an average over the 6 counted days

