## MODIFIED Requirements

### Requirement: Synced entity types
The system SHALL sync exactly the entity types registered in `SyncAdapterRegistry`:
calorie records (entity type `calorie_item`), meals (entity type `meal`), tracking
gaps (entity type `tracking_gap`) and day metric entries (entity type `day_metric`).
Profiles, products, product categories and waking periods SHALL NOT be synced.

#### Scenario: A product is not synced
- **WHEN** the user creates a custom product and runs a sync
- **THEN** no sync entry is pushed for the product

#### Scenario: A tracking gap is synced
- **WHEN** the user creates a tracking gap on a profile linked to a server and runs a sync
- **THEN** a `tracking_gap` sync entry is pushed with the gap as payload

#### Scenario: A day metric is synced
- **WHEN** the user saves a steps value on a profile linked to a server and runs a sync
- **THEN** a `day_metric` sync entry is pushed with the entry as payload

#### Scenario: Two phones enter the same day
- **WHEN** two phones save steps for the same profile and day and both sync
- **THEN** both phones hold one steps value for that day, the one with the later `updatedAt`

#### Scenario: A cleared day metric is synced
- **WHEN** the user clears a value on one phone and both phones sync
- **THEN** the other phone shows a dash for that value

### Requirement: Profile scope
A server sync SHALL push only records, meals, tracking gaps and day metric entries whose
profile is linked to that server, and SHALL apply a pulled record, meal, tracking gap or
day metric entry only when its profile is linked to that server. A folder sync SHALL
treat every local profile as linked.

#### Scenario: Pulled record of an unlinked profile
- **WHEN** a pulled `calorie_item` belongs to a profile that is not linked to the server
- **THEN** the record is not written to the local database

#### Scenario: Pulled gap of an unlinked profile
- **WHEN** a pulled `tracking_gap` belongs to a profile that is not linked to the server
- **THEN** the gap is not written to the local database

#### Scenario: Pulled day metric of an unlinked profile
- **WHEN** a pulled `day_metric` belongs to a profile that is not linked to the server
- **THEN** the entry is not written to the local database

## ADDED Requirements

### Requirement: Server keeps day metrics in the sync log
The server SHALL NOT materialize `day_metric` entries into a table and SHALL store them
in the sync log like any other entity type.

#### Scenario: Day metric pushed from the phone
- **WHEN** the phone pushes a `day_metric` entry
- **THEN** another device pulls that entry and no server table other than `sync_entries` changes
