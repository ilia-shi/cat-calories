# sync Specification

## Purpose

Keep calorie records and meals consistent between the user's devices, a Dart sync
server (`packages/server`) and a shared folder (e.g. Syncthing). The app side lives in
`lib/features/sync/syncer.dart` (`Syncer`); the wire contract and transports live in
`packages/core/lib/features/sync`; the server side is `SyncV2Handler` and
`SyncEntryRepository` in `packages/server`.

## Requirements

### Requirement: Synced entity types
The system SHALL sync exactly the entity types registered in `SyncAdapterRegistry`:
calorie records (entity type `calorie_item`) and meals (entity type `meal`). Profiles,
products, product categories and waking periods SHALL NOT be synced.

#### Scenario: A product is not synced
- **WHEN** the user creates a custom product and runs a sync
- **THEN** no sync entry is pushed for the product

### Requirement: Manual sync trigger
Sync SHALL run only when the user starts it. "Sync all servers" (the quick-sync action
in the app bar and the item in its sheet) SHALL sync every configured server in turn,
then the shared folder if folder sync is enabled. The servers screen SHALL offer a sync
of one server at a time. A sync action SHALL be ignored while the same action is
already running.

#### Scenario: Sync all with folder sync enabled
- **WHEN** two servers are configured, folder sync is enabled and the user taps "Sync all servers"
- **THEN** the first server, the second server and then the folder are synced, in that order

#### Scenario: Double tap during a sync
- **WHEN** a "Sync all servers" run is in progress and the user taps it again
- **THEN** no second run starts

### Requirement: Server discovery
Adding a server SHALL fetch `<url>/.well-known/sync-config` with a 10-second timeout and
store the returned server name, server version, protocol version, auth settings and
transports. Before the request the entered URL SHALL be normalized: surrounding
whitespace and one trailing slash are removed, and a URL without a scheme gets
`http://` when its host is an IPv4 address, `localhost` or `*.localhost`, and
`https://` otherwise.

#### Scenario: Bare hostname
- **WHEN** the user enters `sync.example.com/`
- **THEN** discovery requests `https://sync.example.com/.well-known/sync-config`

#### Scenario: Bare IP address with port
- **WHEN** the user enters `192.168.1.5:8080`
- **THEN** discovery requests `http://192.168.1.5:8080/.well-known/sync-config`

#### Scenario: Server answers with an error status
- **WHEN** the discovery endpoint answers with a status other than 200
- **THEN** adding the server fails with the returned status code in the error

### Requirement: Server sync preconditions
Syncing a server SHALL require stored credentials for that server and at least one
profile linked to it (a `ScopedServerLink`). Without them the server's sync SHALL fail
without any network request.

#### Scenario: Server without credentials
- **WHEN** the user syncs a server they never logged in to
- **THEN** that server's result is failed with the error "No credentials"

#### Scenario: Server without linked profiles
- **WHEN** the user syncs a server that has credentials but no linked profile
- **THEN** that server's result is failed with the error "No linked profiles"

### Requirement: Profile scope
A server sync SHALL push only records and meals whose profile is linked to that
server, and SHALL apply a pulled record or meal only when its profile is linked to
that server. A folder sync SHALL treat every local profile as linked.

#### Scenario: Pulled record of an unlinked profile
- **WHEN** a pulled `calorie_item` belongs to a profile that is not linked to the server
- **THEN** the record is not written to the local database

### Requirement: Server URL failover
A server MAY have several URLs. A server sync SHALL try them in their stored order and
stop at the first URL with which the whole push and pull completes. When every URL
fails, the server's result SHALL be failed with an error starting "All URLs failed"
and naming the last error.

#### Scenario: First URL unreachable
- **WHEN** a server has a LAN URL and a public URL and the LAN URL times out
- **THEN** the sync is repeated in full against the public URL

### Requirement: Push to a server
For each entity type the app SHALL push every in-scope entity on every sync, in
batches of at most 100 entries to `POST /api/v1/sync/push`. Each entry SHALL carry the
entity id, version `1`, an HLC equal to the entity's `updatedAt` as a UTC ISO-8601
string, and the full entity as payload. Each batch SHALL carry a fresh idempotency key.
The server SHALL store an entry when no entry with the same entity type and id exists,
when the incoming version is higher than the stored one, or when the versions are equal
and the incoming HLC is strictly greater. Otherwise the server SHALL keep its entry and
report it as a conflict, and the entry counts as rejected.

#### Scenario: Unchanged record pushed again
- **WHEN** a record was pushed on the previous sync and has not been edited since
- **THEN** the server keeps its stored entry and reports the record as rejected

#### Scenario: Edited record
- **WHEN** a record was edited on the phone after its last push
- **THEN** the server stores the new payload and counts the record as accepted

### Requirement: Push idempotency
The server SHALL remember each idempotency key per user together with its accepted
count. A batch with an already seen key SHALL NOT be applied again, and the server
SHALL answer with the remembered accepted count.

#### Scenario: Retried batch
- **WHEN** a push batch is sent twice with the same idempotency key
- **THEN** the second request changes no entry and returns the same accepted count as the first

### Requirement: Pull from a server
`GET /api/v1/sync/pull` SHALL return only the requesting user's entries of the
requested entity type whose server HLC is greater than the `since` parameter, ordered
by server HLC ascending. `limit` SHALL default to 100 and be capped at 1000. The
response SHALL include `has_more` and a `server_timestamp`. Server HLCs SHALL have the
form `<unix microseconds>-<counter>` and increase monotonically on one server.

#### Scenario: Another user's entries
- **WHEN** user A pulls `calorie_item` entries
- **THEN** entries stored by user B are not returned

#### Scenario: Oversized limit
- **WHEN** a client requests `limit=5000`
- **THEN** at most 1000 entries are returned

### Requirement: Applying pulled entries
For each pulled entry the app SHALL:
- delete the local entity with that id, when the entry is a deletion and the entity exists locally;
- insert the entity, when it does not exist locally;
- overwrite the local entity, only when the pulled `updatedAt` is strictly later than the local one.

A deletion SHALL be applied regardless of profile scope.

#### Scenario: Local copy is newer
- **WHEN** a pulled record has `updatedAt` 10:00 and the local copy has `updatedAt` 10:05
- **THEN** the local copy is kept

#### Scenario: Same timestamp
- **WHEN** a pulled record has the same `updatedAt` as the local copy
- **THEN** the local copy is kept

#### Scenario: Deleted in the web client
- **WHEN** the user deletes a record in the web client and then syncs the phone
- **THEN** the record is deleted on the phone and counted in "deleted"

### Requirement: Web client edits enter the sync log
The server SHALL write a `calorie_item` sync entry with the stored version plus one
whenever the web client creates, updates or deletes a calorie record through
`/api/records`. A deletion SHALL be written as an entry with `is_deleted` set and no
payload. The payload's `profile_id` SHALL be the phone's profile id, taken from the
record's existing sync entry or from any other `calorie_item` entry of the same user,
so the phone recognizes the record when it pulls it.

#### Scenario: Record edited on the web
- **WHEN** a record pushed from the phone is edited in the web client
- **THEN** its sync entry gets the next version and keeps the phone's `profile_id`

### Requirement: Server materializes calorie records
Every accepted `calorie_item` entry SHALL be copied into the server's `calorie_items`
table under the user's server-side profile, so the web client can read it; an
accepted deletion SHALL remove the row. On startup the server SHALL materialize any
non-deleted `calorie_item` entry that has no row yet. A legacy payload field
`created_at_day` SHALL be accepted in place of `record_day`.

#### Scenario: Server restarted after a lost write
- **WHEN** a `calorie_item` entry exists without a matching `calorie_items` row and the server starts
- **THEN** the row is created from the entry's payload

### Requirement: Authentication
Push and pull SHALL require an authenticated user. A 401 response SHALL surface to the
app as an authentication error rather than a generic transport error.

#### Scenario: Expired token
- **WHEN** the server answers a push with 401
- **THEN** the sync of that URL fails with "Token expired"

### Requirement: Folder sync storage
Folder sync SHALL identify the device by a UUID stored in the app-support directory
(never in the shared folder) and SHALL write a descriptive
`v1/meta/device-<id>.json` into the shared folder once. Each device SHALL append only
to its own logs, one NDJSON file per entity type at
`v1/logs/<deviceId>/<entityType>.ndjson`, and SHALL never rewrite or truncate a log.
Before syncing, the app SHALL check the folder is writable by creating and deleting a
probe file; when the check fails the folder's result SHALL be failed with
"Folder not writable".

#### Scenario: Read-only folder
- **WHEN** the shared folder cannot be written
- **THEN** the folder sync fails with an error starting "Folder not writable"

### Requirement: Folder push
Folder sync SHALL append an entity to its own log only when the log has no line for
that entity, or when the entity's `updatedAt` is later than the latest HLC already
logged for it.

#### Scenario: Nothing changed since the last folder sync
- **WHEN** no record or meal was edited since the last folder sync
- **THEN** nothing is appended to the device's logs

### Requirement: Folder pull
Folder sync SHALL read every other device's logs for the entity type, including
Syncthing `.sync-conflict-*` copies, in path order, resuming each file from a per-file
byte offset stored locally. It SHALL ignore the HLC watermark, because logs from an
offline device can arrive after newer entries. A line that is not a valid sync entry
SHALL be skipped and not read again. Pulled entries SHALL be applied by the same rules
as server pulls.

#### Scenario: Offline device's log arrives late
- **WHEN** device B's log arrives with entries older than ones already pulled from device C
- **THEN** device B's entries are still read and applied

#### Scenario: Corrupt line
- **WHEN** a log line is not valid JSON or lacks a required field
- **THEN** that line is skipped and the following lines are still applied

### Requirement: Sync result message
After a sync the app SHALL report the totals across all targets as "Synced: N pushed,
M pulled, K deleted", leaving out zero parts, or "Synced, no changes" when all three
are zero. When every target failed, it SHALL report "Sync failed".

#### Scenario: Only pulls happened
- **WHEN** a sync pulled 3 records and pushed and deleted none
- **THEN** the message is "Synced: 3 pulled"
