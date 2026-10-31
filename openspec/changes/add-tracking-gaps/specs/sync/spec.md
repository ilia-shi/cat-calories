## MODIFIED Requirements

### Requirement: Synced entity types
The system SHALL sync exactly the entity types registered in `SyncAdapterRegistry`:
calorie records (entity type `calorie_item`), meals (entity type `meal`) and tracking
gaps (entity type `tracking_gap`). Profiles, products, product categories and waking
periods SHALL NOT be synced.

#### Scenario: A product is not synced
- **WHEN** the user creates a custom product and runs a sync
- **THEN** no sync entry is pushed for the product

#### Scenario: A tracking gap is synced
- **WHEN** the user creates a tracking gap on a profile linked to a server and runs a sync
- **THEN** a `tracking_gap` sync entry is pushed with the gap as payload

### Requirement: Profile scope
A server sync SHALL push only records, meals and tracking gaps whose profile is linked to
that server, and SHALL apply a pulled record, meal or tracking gap only when its profile
is linked to that server. A folder sync SHALL treat every local profile as linked.

#### Scenario: Pulled record of an unlinked profile
- **WHEN** a pulled `calorie_item` belongs to a profile that is not linked to the server
- **THEN** the record is not written to the local database

#### Scenario: Pulled gap of an unlinked profile
- **WHEN** a pulled `tracking_gap` belongs to a profile that is not linked to the server
- **THEN** the gap is not written to the local database

## ADDED Requirements

### Requirement: Server reads tracking gaps from the sync log
The server SHALL NOT materialize `tracking_gap` entries into a table. To compute
statistics it SHALL read the requesting user's `tracking_gap` entries and ignore those
marked as deleted.

#### Scenario: Gap pushed from the phone
- **WHEN** a gap covering yesterday is pushed and the web client loads `/api/home`
- **THEN** `avg_7_days` leaves yesterday out

#### Scenario: Gap deleted on the phone
- **WHEN** the phone pushes a gap marked as deleted
- **THEN** the next `/api/home` response counts that gap's days again
