# Cat Calories master plan — meals, money, LLM analysis & file-based sync

Union of two formerly separate plans (meal tracking/LLM analysis and file-based
sync, originally drafted as local working notes), which turn out to be two halves of
one product idea:

> **A synced folder is the app's entire external interface.** It is simultaneously the
> multi-device sync medium (append-only op logs, machine-facing) and the AI interface
> (LLM-readable exports, human-facing). The app itself stays offline, local-first and
> AI-free; the user points Syncthing (or any folder-sync tool) at one directory and
> gets both device sync and "paste my log into any LLM" analysis.

## How the two halves fit together

```
<synced-root>/cat-calories/
  v1/                                ← Part II: sync (machine-facing)
    logs/<deviceId>/<entity>.ndjson    append-only op logs, single writer per file
    snapshots/  meta/
  export/                            ← Part I: analysis (LLM-facing)
    llm-log-<deviceId>.md              markdown nutrition log (meal plan's export)
    current-state.json                 optional materialized "what's true now"
```

Integration points (the glue that neither plan states alone):

1. **One folder setting.** The meal plan's "export directory for Syncthing" and the
   sync plan's "synced folder path" are the *same* profile setting: the synced root.
   Export works even if file-sync is never enabled (any folder), and vice versa.
2. **The tracks are orthogonal — build in parallel or in either order.** The file
   transport moves opaque `payload = entity.toJson()` blobs, so every Part I schema
   change (Meal entity, `mealId`, price/cost/currency fields) rides through it with
   zero transport work. Conversely, `Meal` only needs a registered
   `SyncAdapter<Meal>` and it automatically gets its own `meal.ndjson` per device.
3. **The single-writer rule extends to exports.** Anything written into the synced
   root must have exactly one writer per file: the LLM export is
   `llm-log-<deviceId>.md` (or one designated exporting device), never a shared
   filename — same reasoning that keeps the op logs conflict-free under Syncthing.
4. **After sync converges, any device's export is complete.** Each device holds the
   full merged state, so its export contains all devices' history; the LLM (or user)
   just reads the freshest file. Auto-export can hook the end of a successful sync
   session — the moment state is most complete.
5. **Shared philosophy, shared non-goals**: no in-app AI, no backend dependence, no
   network data sources (FX rates, price databases); plain text at rest; the LLM does
   the smart work at analysis time.

---

# Part I — Meal tracking, money signals & LLM export

Goal: track meals with just enough signal (cost, cook time, taste, satiety) to let an
external LLM produce daily eating recommendations and "healthier / cheaper / tastier /
faster" advice — while keeping in-app tracking effort near zero.

## What we already have (build on it, don't duplicate)

- `CalorieRecord.eatenAt` is already nullable and `isEaten()` exists
  (`packages/core/.../calorie_tracking/domain/calorie_record.dart`). "Planned but not
  yet eaten" records are already representable.
- `PlannedCalorieRecord` implements `PlanItem` (planned/completed/skipped) in
  `packages/core/.../planning/`. The planning scaffold exists; it needs UX, not a new
  model.
- `Product` has per-100g macros + `packageWeightGrams`, so per-ingredient math is
  solved.
- `CalorieExporter` exists (JSON). We need a second, LLM-oriented text format.

## Design decision: planned records AND meal grouping — they compose

1. **Planned records**: keep `eatenAt` empty on creation when planning; a one-tap
   "mark eaten" sets it. This is how "prepare today, eat tomorrow" works with no new
   entity.
2. **Meal grouping**: a new `Meal` entity that groups calorie records (ingredients)
   and carries the human/LLM context: description, cook time, taste, satiety.
   Ingredient-level records stay untouched, so all existing per-100g and day-total
   math keeps working.

A planned meal = a `Meal` whose records all have `eatenAt == null`. Marking the meal
eaten stamps all its records at once — one tap instead of N.

## Data model changes

### New entity: `Meal` (packages/core, under `calorie_tracking` or its own feature)

```dart
final class Meal {
  String? id;
  String profileId;
  String title;              // "Chicken curry"
  String? notes;             // free text, goes verbatim into LLM export
  DateTime createdAt;
  DateTime updatedAt;
  DateTime? eatenAt;         // null => planned/being-prepared
  int? cookingMinutes;       // optional, chip-picked
  int? tasteRating;          // 1..5, optional
  int? satietyRating;        // 1..5 "how well it satisfied hunger", optional
  double? totalCookedWeightGrams; // enables "save as product" (per-100g of the dish)
}
```

### `CalorieRecord`: add nullable columns

- `mealId` (nullable FK). Records without a meal behave exactly as today — grouping is
  always optional.
- `costValue` + `costCurrency` — cost **snapshotted at logging time** (see Currency &
  travel below).

### `Product`: add price (this is where value-for-money comes from, effort-free)

- `pricePerPackage` (nullable double) + `priceCurrency` (ISO 4217 string, prefilled
  from a profile-level default currency) + existing `packageWeightGrams` → cost per
  gram.
- Entered **once per product**, never per record. Every record with `productId` +
  `weightGrams` then gets cost computed automatically; meal cost = sum of ingredients.
- Optionally `priceUpdatedAt` so stale prices can be flagged in export.
- Semantics: **"the price I currently pay"**, not a market survey. No per-market or
  per-city price ranges — that's a crowdsourced-database problem, and the LLM only
  needs "is this food cheap per gram of protein *for this user*", where
  market-to-market variance is noise.

### Currency & travel

- **Snapshot cost onto data at logging time**: `costValue` + `costCurrency` on
  `CalorieRecord` (rolled up on `Meal`), computed from the product's price when the
  record is created. Analysis reads historical exports, so what matters is what the
  food cost then and there; once snapshotted, the product's price can change freely
  without corrupting history.
- **Edit/recompute story for the snapshot** (no value is write-once):
  - `costValue`/`costCurrency` are **directly editable** on the record — e.g., you
    actually paid a promo price, or the snapshot was taken from a wrong product
    price. A manual edit sets a `costIsManual` flag on the record.
  - A per-record **"Recompute from product"** action re-derives cost from the
    product's *current* price and weight, and clears `costIsManual` — the fix-path
    when a product price was entered wrong and old records inherited it (offer it
    bulk from the product form: "recompute N records using this product").
  - Changing a record's `weightGrams` or `productId` **auto-recomputes** the
    snapshot, *unless* `costIsManual` is set — a manual correction is never silently
    clobbered; the edit sheet just shows a hint that cost is manual with a one-tap
    recompute.
  - **Meal cost is always derived** (sum of ingredient costs), never edited directly
    — correct the ingredient records instead.
  - The export prints whatever is stored, so corrections retroactively improve the
    LLM's history — consistent with "enrichment pays retroactively".
- Traveling therefore = update a product's price + currency once per country as you
  buy it (first entry is unavoidable anyway). Old records keep their old
  cost/currency.
- **Remembered prices** (optional convenience, not a region model): a small
  `ProductPrice` list per product — `amount`, `currency`, free-text `label`
  ("home", "Batumi"), `updatedAt` — rendered as one-tap chips in the product form so
  returning home doesn't mean retyping. No location entity, no global "current city"
  state to forget to switch. **Superseded by the purchase log (increment G)** if that
  ships: purchase history *is* price history, so don't build both.
- **No FX conversion in-app**: it needs a rates source and network calls, and the LLM
  normalizes mixed currencies fine. The export just reports each cost in its original
  currency and notes the profile's default.
- Anti-pattern to avoid: a separate "travel profile" — products are per-profile, so it
  would fork the product catalog and split the history the LLM needs.

### Purchase log (budget vs. consumption)

Cost snapshots measure *consumption* ("what did the food I ate cost"); a purchase log
measures *spending* (money out at the till). They are complementary, not alternatives —
and the gap between them is the most interesting derived number: **food waste** (bought
but never eaten), plus untracked food spending (spices, coffee, spoiled items).

- **`Purchase` entity**: `id`, `profileId`, `occurredAt`, `title` (free text),
  `totalPrice`, `currency` (prefilled from profile default), optional `productId`
  link, optional `packageCount`. Deliberately flat — no receipts, no line-item
  hierarchy, no store entity. One purchase row ≈ one thing bought.
- **Purchases maintain product prices as a side effect.** Logging a purchase linked to
  a product offers a one-tap "update product price" (price = totalPrice ÷
  packageCount). This replaces manual price upkeep entirely — traveling means prices
  refresh themselves the first time you shop, and past purchases double as labeled
  price history (which is why the remembered-prices chips above become redundant).
- **Linking is optional.** Free-text "chicken, 8.50" is fine — the LLM correlates
  purchases to products/records by name. A `productId` link just makes correlation
  exact and enables the price refresh.
- **Export**: a `## Purchases` section (chronological, per-currency period totals) so
  the LLM can compare spend vs. consumed cost, estimate waste, and suggest cheaper
  swaps. The preamble must state that the purchase log may be partial — "unknown, not
  zero" — or budget analysis will mislead.
- **Laziness contract applies in full**: purchases are a fully optional habit; nothing
  else depends on them existing. Quick-add from a product card ("bought this — how
  much?", price prefilled from last purchase) keeps a shopping trip to a few taps.

## Laziness contract (progressive enrichment)

The floor never rises: logging "apple, 52 kcal" as a bare free-text record — no
product, no weight, no meal, no price — must always work exactly as it does today, and
every feature in this plan is an *optional enrichment layer* on top of that.

- **Every field degrades to null silently.** No price → cost rollups just omit that
  item (shown as "≥" partial sums or hidden); no ratings → no ratings; no meal →
  record lists under "Ungrouped". Nothing is ever blocked on missing data.
- **The app never nags to "complete" data.** No badges, no red counters, no "add price
  to 12 products" prompts. The single dismissible rate-recent-meals row is the only
  proactive surface, and dismissing it is permanent for those meals.
- **The user never types an ISO code.** Default currency is picked once (settings or
  first price entry, defaulting from device locale); after that the currency field is
  prefilled and hidden behind an "other currency" affordance used only when traveling.
- **Enrichment pays retroactively, so it never feels urgent.** Adding a price to a
  product today improves value-for-money math on *future* records automatically;
  sparse data is the expected steady state — not a deficiency.
- **The export declares sparseness to the LLM.** A preamble line ("costs, ratings and
  cook times are logged opportunistically; treat missing values as unknown, not zero")
  so the analysis works with whatever exists instead of complaining about gaps.

## UX flows (friction budget: seconds, everything skippable)

### 1. Prepare today → cook/eat tomorrow (primary calculation-saver)

- "New meal" → add ingredients from products (weights → calories auto-computed). All
  records created with `eatenAt = null`; meal shows as **Planned**.
- Next day, open the meal in "cooking mode": edit weights inline, remove/add
  ingredients (actual amounts often differ from the plan), totals recompute live.
- Tap **"Eaten"** → stamps `eatenAt` on the meal and all its records. Done.

### 2. Repeat a meal ("cook it again")

- Any past meal has **Duplicate** → new planned meal with the same ingredient list and
  last-used weights, ready to tweak. Cheaper than a separate Recipe/Template entity;
  add a template entity later only if duplication proves insufficient.

### 3. Leftovers: "Save meal as product"

- After cooking, if the user enters `totalCookedWeightGrams`, one action creates a
  `Product` with computed per-100g kcal/macros (totals ÷ cooked weight) and per-100g
  cost. Eating leftovers tomorrow = one ordinary record by weight.

### 4. Group existing records after the fact

- Multi-select records on the day view → "Group as meal". For people who log first and
  organize later (or never — grouping stays optional).

### 5. Ratings without nagging (lazy, dismissible)

- Never block the "Eaten" action with a rating form.
- A small dismissible "Rate recent meals" row (dashboard or day view) listing unrated
  meals eaten in the last ~48h; tapping shows two 5-dot rows (taste, satiety) +
  optional note. Two taps total; ignoring it forever is fine.
- Satiety phrasing matters for the LLM: "How long did it keep you full?" is more
  actionable than "did you like it".

### 6. Cook time

- Optional chips on the meal sheet: `10 / 20 / 30 / 45 / 60+ min`. One tap, no timer,
  no free-form typing.

## LLM export (the analysis product)

Markdown/plain-text export next to the JSON one (`CalorieExporter.exportLlmText`),
written to the share sheet and to `export/llm-log-<deviceId>.md` under the synced root
(single-writer filename — see integration point 3). Manual export button + optional
"auto-export after successful sync / on day close" toggle.

Format sketch — compact, self-describing, stable ordering so diffs sync cleanly:

```markdown
# Cat Calories — nutrition log
Profile: Ilya · Daily goal: 1800 kcal
Period: 2026-06-25 .. 2026-07-01
Costs are snapshotted at eating time in the currency then in use (default EUR; some
entries GEL from travel). Convert as needed when comparing.

## 2026-06-30 — total 1740 kcal (P 92g / F 61g / C 190g) · cost 6.40
### Meal: Chicken curry — 620 kcal · 2.10 · cook 30 min · taste 4/5 · satiety 5/5
- chicken thigh 250g — 395 kcal (P 42 / F 25 / C 0) · 1.20
- rice 80g (dry) — 288 kcal · 0.25
- coconut milk 100g — 180 kcal · 0.65
Notes: less oil than last time, still good.
### Ungrouped
- banana 120g — 107 kcal · 0.20

## Planned (not eaten yet)
### Meal: Overnight oats — 410 kcal (planned for 2026-07-02)
...
```

Also embed a short **preamble for the LLM** (goals + question templates like "suggest
tomorrow's meals from my usual products; optimize health/cost/time"), editable in
settings, plus the sparseness note from the laziness contract. Include a
`## Products` appendix (per-100g macros, price, uses count) — the vocabulary the LLM
recommends *from*.

Pure formatting lives in `packages/core` (reusable by web/server); file/share I/O
stays in the app.

---

# Part II — File-based sync (Syncthing-friendly)

Replace (or sit alongside) the HTTP sync server with the **synced folder** of plain
append-only log files, so devices reconcile through Syncthing / a cloud folder and any
device's LLM tooling can read the raw history.

## TL;DR

- Add a `FileSyncTransport implements SyncTransport` in
  `packages/core/lib/features/sync/transport/file/`. It slots in beside
  `RestSyncTransport` — **`SyncEngine`, `SyncAdapter`, HLC/version/LWW merge, and the
  sqflite materialization all stay unchanged.**
- Storage = **one append-only NDJSON log per `(device, entity_type)`**. A device only
  ever appends to *its own* files, so Syncthing never has to merge a file and never
  produces a real conflict.
- `push` = append my batch as JSON lines. `pull` = read every *other* device's logs
  past a per-file cursor, hand the entries to the engine, which LWW-merges them
  exactly as it merges entries pulled from the server today.
- This works because the sync layer is already a CRDT-style op log; the folder just
  replaces the server's role as a dumb relay.

## Why it fits the current architecture

A server "sync entry" today (`sync_entry_repository.dart`) is already self-contained
and mergeable:

```
{ entity_type, entity_id, scope, hlc, version, is_deleted, payload }
```

`sync_v2_handler.dart` does almost no intelligent work — it relays entries, rejects
stale ones by `version` then `hlc` (`upsert`), and materializes `calorie_item` rows.
The client side (`SyncEngine` in `transport/sync_transport.dart`) already:

- pushes per `entity_type` in batches (`_pushEntityType`),
- pulls per `entity_type` since an HLC anchor (`_pullEntityType`),
- applies pulled entries through `SyncStorage.applyPulled`, whose underlying upsert is
  **idempotent and order-independent** (older/equal version → rejected).

So the only thing the server uniquely provides is *a shared place to drop entries and
read others' entries back*. A synced folder is exactly that.

## Storage layout

See the unified layout at the top. **One file per `(device, entity_type)`** (not one
giant file, not one file per entity):

- Per-device ⇒ single-writer per file ⇒ no Syncthing merge, no `.sync-conflict` churn.
- Per-entity-type ⇒ `pull(entityType)` reads exactly the relevant files and each file
  gets an independent cursor; no scanning unrelated data.
- A whole-folder JSON or a synced SQLite DB is explicitly rejected: Syncthing warns
  against syncing live DB files (WAL corruption), and a single shared JSON guarantees
  conflict copies on every concurrent edit.
- Part I's `Meal` (and any future entity) appears here automatically as
  `meal.ndjson` once its `SyncAdapter` is registered — no transport changes.

### Log record (one JSON object per line, NDJSON)

```json
{ "entity_id": "…", "entity_type": "calorie_item", "scope": "<profileId>",
  "version": 3, "hlc": "1719772800000000-0", "is_deleted": false,
  "payload": { "…entity.toJson()…": true }, "device_id": "<deviceId>", "op_ts": 1719772800123 }
```

- `version` + `hlc` drive LWW exactly as today. `entity_type`/`device_id` are
  redundant with the path but kept so a single line is self-describing for AI and
  recovery.
- `payload` is `null` when `is_deleted` (soft delete — already in the model).
- Append-only: an edit appends a new line with a higher `version`; the merge keeps the
  winner. A torn trailing line after a crash is simply discarded on read.

## `FileSyncTransport` (implements `SyncTransport`)

Implement the existing four-method contract; no engine changes.

```dart
final class FileSyncTransport implements SyncTransport {
  FileSyncTransport({ required Directory root, required String deviceId,
                      required FileCursorStore cursors });

  @override Future<SyncResult> push(SyncBatch batch);          // append my lines
  @override Future<PullResult> pull({required String entityType,
                                     required String sinceHlc, required int limit});
  @override Future<bool> healthCheck();                        // root exists & writable
  @override Stream<SyncEntry> get remoteChanges;               // Directory.watch (optional)
  @override Future<void> dispose();
}
```

**push** — append each `batch.entries` line to
`logs/<myDeviceId>/<entityType>.ndjson` (create dirs on first use), flush/fsync,
return `SyncResult(accepted: n)`. Because the engine writes its own ops, push never
conflicts with itself; a retried batch just re-appends lines that merge to a no-op
(see Idempotency).

**pull** — the important part. Enumerate `logs/<otherDeviceId>/<entityType>.ndjson`
for every device **except mine**, read each file *from its stored cursor onward*,
parse lines into `SyncEntry`, advance that file's cursor, and return up to `limit`
entries (`hasMore` if any file still has unread bytes). `serverTimestamp` = max `hlc`
returned.

### Cursor model — why not the engine's single HLC anchor

The REST flow relies on the server re-stamping every entry with a monotonic
`server_hlc`, so one scalar `sinceHlc` per `(entityType, serverId)` is a safe
watermark. **File delivery is out-of-order**: an offline device's log can arrive
*after* you've advanced past its `hlc` values, and a single watermark would skip them
forever.

Fix: keep a **per-file cursor** (byte offset, or last consumed line's `hlc`) in a
**local, non-synced** state store — `FileCursorStore`, persisted in app-support dir,
**not** in the synced folder. Each log is internally monotonic and append-only, so a
per-file offset is always correct regardless of cross-device delivery order. The
engine's `getLastPulledHlc/setLastPulledHlc` still runs but is redundant for this
transport (`pull` ignores `sinceHlc` and trusts its own cursors).

Simplest correct fallback if you don't want a cursor store: ignore cursors, re-read
all logs every sync, and lean on the idempotent LWW upsert to drop already-applied
entries. O(total) per sync — fine for a personal food log (entries are ~300 B; years ≈
a few MB). Add cursors later as the optimization.

## Merge, conflicts, idempotency

- **Merge** is unchanged: pulled `SyncEntry`s go through `SyncStorage.applyPulled` →
  the existing version-then-HLC LWW upsert. No new conflict logic.
- **True concurrent edits** of the same entity resolve by LWW — same semantics (and
  same rare data-loss tradeoff) as the current server. Acceptable for this domain.
- **Syncthing `.sync-conflict-*` files**: with strict per-device ownership they
  shouldn't occur, but if one ever does, it's *also a valid append-only log* — have
  `pull` glob `*.ndjson` (including `*sync-conflict*`) and merge it. Conflict copies
  become harmless because entries are idempotent.
- **Push idempotency**: a retried `push` may double-append identical lines. Harmless —
  duplicates have equal `version`/`hlc` and are rejected on apply; they only waste a
  few bytes. Optional dedupe: skip appending if the last line for that `entity_id`
  already has `version >= incoming`.

## Device identity & local state (never synced)

- On first run, generate a stable `deviceId` (uuid), store it in app-support dir and
  in `meta/device-<deviceId>.json`. It names this device's log files forever — and its
  `llm-log-<deviceId>.md` export.
- `FileCursorStore` (per-file read offsets) lives next to it — **must not** be in the
  synced folder, or devices would clobber each other's cursors.

## Compaction / retention

Logs grow unbounded in principle. For this app's volume, **defer it** — note the path:

- A device may write an **immutable** `snapshots/snapshot-<deviceId>-<hlc>.ndjson`
  containing the full current LWW state it knows, plus a watermark. Immutable,
  globally unique names ⇒ still single-writer, still conflict-free.
- Only the *owning* device may later truncate its own logs below an `hlc` that every
  known device has acknowledged (acks tracked via each device's snapshot watermark).
- Until that's needed, logs stay small; skip compaction.

## What does NOT change

- `packages/core` domain models, `SyncAdapter`s, `SyncAdapterRegistry`.
- `SyncEngine`, `SyncScheduler`, `SyncStorage` contract, sqflite materialization.
- The `import_lint` boundaries — `FileSyncTransport` lives under
  `features/sync/transport/file/`, pure Dart, no Flutter.

## What this costs / breaks (decide before building)

1. **Web client loses its backend.** `web/` talks to the server REST API; a browser
   can't read a Syncthing folder. Either keep a local-only server for web, make web a
   reader of the `export/` files, or accept mobile-only sync. **Biggest call.**
2. **iOS**: no real Syncthing; background sync is restricted. Android is fine. iPhone
   would need iCloud Drive / another folder provider with its own quirks.
3. **Auth/sharing**: trust drops to Syncthing's device level — good for *your*
   devices, not for multi-user sharing. OAuth/Casdoor/Traefik go away.
4. **No realtime/push** beyond `Directory.watch` + Syncthing propagation latency.
5. Folder is plaintext at rest; rely on Syncthing untrusted-device encryption or OS
   disk encryption if that matters.

---

# Unified roadmap

Three tracks. Each increment leaves the app fully working and useful on its own; after
**A**, all three tracks are independent and can be built in any order or in parallel.
Follow `docs/architecture.md` layering and the `add-feature` skill for scaffolding.

```
A (LLM export v1) ──→ B (price & cost) ──→ G (purchase log) ──→ F (polish)
          └─────────→ C (meal grouping) ──→ D (planned/cooking)
                                        └─→ E (meal signals)

S1 (FileSyncTransport core) ──→ S2 (DI + folder setting) ──→ S3 (watch, snapshots)
```

Cross-track glue: **S2's folder setting and A's export directory are the same
setting** (the synced root); A's auto-export hooks the end of an S-track sync session
when both exist; C's `Meal` needs a `SyncAdapter<Meal>` which serves both the REST
server *and* the file transport for free.

### Meal/money track (Part I)

- **A. LLM export v1** — *no schema changes, immediate value.* `exportLlmText` over
  data that exists today: days, records, products appendix, editable goal preamble;
  export-directory setting; optional auto-export toggle. Every later increment only
  *enriches* this file.
- **B. Price & cost (independent of meals)** — `pricePerPackage` + `priceCurrency` on
  `Product`, profile default currency, cost snapshot columns on `CalorieRecord`
  (`costValue`, `costCurrency`, `costIsManual`) with the edit/recompute story from
  Currency & travel, cost rollups on record/day, cost lines in the export. sqflite
  migration + `api/openapi.yaml` update (then `make test-dart` + `make test-web`).
  Fully useful without meals.
- **C. Meal grouping** — `Meal` model + repository interface in `packages/core`;
  `mealId` on `CalorieRecord`; migration, app repository, `SyncAdapter<Meal>`, openapi
  update; day-view UI: create meal, add ingredients, group existing records, "Eaten"
  stamps all records; meal sections in the export. Useful standalone as organization +
  LLM context.
- **D. Planned meals & cooking mode** *(needs C)* — "Planned" section over
  `eatenAt == null` meals using the existing `PlanItem` machinery; cooking-mode inline
  editing of weights/ingredients; duplicate meal (implement
  `PlannedCalorieRecord.copy()`, currently `UnimplementedError`). The
  calculation-time win.
- **E. Meal signals** *(needs C, independent of D)* — `cookingMinutes` chips +
  taste/satiety lazy rating row; signal annotations in the export.
- **G. Purchase log** *(needs B for the price-refresh side effect; export section
  needs A only)* — `Purchase` entity + migration + sync adapter + openapi; quick-add
  UX (from product card and standalone); one-tap product-price refresh from a linked
  purchase; `## Purchases` export section with per-currency period totals and a
  partial-data caveat in the preamble. Delivers budget-vs-consumption and waste
  analysis; supersedes the remembered-prices idea.
- **F. Polish (each item independent)** — "save meal as product" (needs C);
  stale-price flagging (needs B); per-week summary in the export (needs A only).
  (Remembered-price chips dropped — superseded by G.)

### Sync track (Part II)

- **S1. Transport core** *(pure Dart, testable in isolation)* —
  `packages/core/.../transport/file/`: `file_sync_transport.dart`,
  `file_transport_config.dart` (`implements TransportConfig`), `ndjson_log.dart`
  (append + cursored reader), `file_cursor_store.dart`, `device_identity.dart`.
  Ship with the full-rescan fallback if the cursor store is deferred.
- **S2. App wiring** *(needs S1)* — DI in `lib/common/service_registry.dart`: a
  `ServerConnection` with `FileSyncTransport` (pseudo-server, e.g.
  `serverId: "file-sync"`) via `engine.addServer(...)`; the shared synced-root
  setting; last-sync status from `SyncSessionResult`.
- **S3. Niceties** *(needs S2)* — `Directory.watch` → `scheduler.syncNow()`;
  `export/current-state.json` writer; snapshot/compaction only if logs ever matter.

### Testing (both tracks)

- Part I: `dart test` in `packages/core` for Meal/cost logic; `flutter analyze` +
  `make arch`; `make test-dart` + `make test-web` after every openapi change.
- Part II unit: append→read round-trip; cursor survives restart; torn last line
  ignored; out-of-order multi-device delivery converges; duplicate push lines are
  no-ops. Integration: two `FileSyncTransport`s over a shared temp dir reach identical
  materialized state regardless of sync order.

---

# Combined non-goals

- No mandatory fields anywhere: a bare calorie record stays a first-class citizen.
- No in-app AI, no network calls for analysis — the synced folder is the only
  interface; the LLM does the smart work at analysis time.
- No recipe/step editor, no cooking timers, no per-ingredient ratings.
- No price history/receipt tracking — one current price per product (plus optional
  remembered-price chips) is enough.
- No FX rates, no currency conversion, no per-city/per-market price databases — costs
  are snapshotted in their original currency.
- No synced SQLite file, no single shared JSON state file — append-only single-writer
  logs only.
- No new conflict-resolution logic — the existing version-then-HLC LWW upsert is the
  merge, for both transports.

# Open questions

1. **Web client's future** (sync cost #1): local-only server, reader of `export/`
   files, or mobile-only sync? Biggest architectural call in the whole plan.
2. Cursor store from day one, or ship S1 with the full-rescan fallback first?
3. Keep the REST server as an optional second `ServerConnection` (file + server
   coexisting), or remove it once file sync proves out?
4. LLM export writer: every device writes `llm-log-<deviceId>.md`, or one designated
   exporting device to keep the export dir minimal?
5. Which increment order after A — money (B) or meals (C) first? (Plan supports
   either.)
