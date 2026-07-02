---
name: design-feature
description: Design-thinking discipline for planning any new feature or UX functionality in Cat Calories. Use BEFORE writing implementation code, whenever asked to design, plan, propose, or think through a feature, data-model change, or UX flow. Covers splitting big features into independently shippable increments, writing plans as markdown docs in .stuff/, keeping user input optional (nullable-first fields, no mandatory forms), and making every user-entered value editable later.
---

# Designing a feature or UX flow

Four rules, learned from planning meals/pricing/sync. Apply all of them to every
design conversation before any code is written.

## 1. Split into self-contained increments

Never plan a big feature as one deliverable. Break it into increments where **each
one leaves the app fully working and useful on its own** — ship one, use it for a
while, decide whether the next is still wanted.

- Draw the dependency graph explicitly (ASCII is fine). Watch for phases that
  secretly bundle two independent dependency chains — split them into parallel
  tracks that can be built in either order.
- Order by value ÷ risk: increments with **no schema changes** and immediate user
  value ship first (e.g., an export over existing data before any new entity).
- A later increment may only *enrich* an earlier one, never be required to make it
  useful.

## 2. Plans are markdown documents, always

Every design/plan produced in a conversation gets written to a markdown file under
`.stuff/` (e.g., `.stuff/<topic>_plan.md`) — never left only in chat output.

- Update the same file as the design iterates; it is the artifact, chat is not.
- Include: what already exists in the codebase to build on (with file paths),
  data-model sketches, UX flows, the increment roadmap with dependency graph, and an
  explicit **non-goals** list protecting the design's constraints.
- When plans merge or supersede each other, write the union as a new doc and leave
  originals in place for the user to delete.

## 3. Don't make the user fill fields (nullable-first)

The floor never rises: the simplest existing flow (e.g., a bare free-text calorie
record) must keep working unchanged. Everything new is an optional enrichment layer.

- New columns are **nullable wherever possible**; every feature degrades silently
  when its data is absent (omit from rollups, hide the section — never block).
- No nagging: no badges, counters, or "complete your data" prompts. At most one
  dismissible, low-key surface for optional input.
- Enter-once, reuse-everywhere: attach data at the highest level that serves the
  goal (price on the product, not on every record; rating on the meal, not per
  ingredient).
- Prefill everything prefillable (locale → currency, last-used values → new entry);
  the user should never type codes or repeat themselves.

## 4. Every value stays editable

Users make mistakes and learn better numbers later; no field is write-once.

- Any user-entered or auto-filled value (timestamps, weights, prices, ratings,
  titles, grouping) must be changeable after the fact through normal UI, not by
  deleting and re-creating.
- When a value is **snapshotted/denormalized** at event time (e.g., cost frozen on a
  record), editing must still work: allow direct edit of the snapshot and/or a
  "recompute from current source" action — and state in the plan which one.
- Auto-set values (like `eatenAt` stamped on completion) need an obvious undo/clear
  path (`setUncompleted`-style), not just a setter.
