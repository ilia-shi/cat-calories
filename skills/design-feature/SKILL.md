---
name: design-feature
description: Design-thinking discipline for planning any new feature or UX functionality in Cat Calories. Use BEFORE writing implementation code, whenever asked to design, plan, propose, or think through a feature, data-model change, or UX flow. Covers splitting big features into independently shippable increments, writing plans as markdown docs in .stuff/, keeping user input optional (nullable-first fields, no mandatory forms), and making every user-entered value editable later. Do NOT use for pure implementation of an already-agreed plan, or for bug fixes with no new data/UX.
---

# Designing a feature or UX flow

**STOP. Do not write any implementation code during this skill.** The only output is a
plan document. If you find yourself editing files under `lib/`, `packages/`, or `web/`,
you have left this skill — go back.

Four rules, learned from planning meals/pricing/sync. You must apply all four. This
skill is done in two steps: **(A)** fill in the worksheet below with written answers,
then **(B)** turn the worksheet into a plan document. Do not skip the worksheet — a
plan produced without answering every question is incomplete.

---

## Step A — Answer the worksheet (write every answer explicitly)

Copy these questions and answer each one in prose. An unanswered or "N/A" question is a
red flag: re-read the matching rule before you accept it.

### A1. Increments (Rule 1 — split into self-contained pieces)

- **List the increments, smallest first.** Give each a one-line name.
- **For EACH increment, answer:** "If we ship only this one and stop, is the app still
  fully working and useful?" It must be **yes** for every increment. If any answer is
  no, that increment is too big or mis-ordered — re-split.
- **Draw the dependency graph** (ASCII arrows, `A → B` means B needs A).
- **Does any increment secretly bundle two independent chains?** If a single increment
  depends on two unrelated predecessors, split it into parallel tracks.
- **What ships first, and why is it lowest risk?** The first increment should have **no
  schema change** if possible and deliver value over data that already exists (e.g. an
  export before any new entity).

> Good answer example: "Increments: (1) show cost on existing records — read-only,
> no schema change; (2) editable price on product; (3) cost snapshot on record.
> Graph: 2 → 3, 1 is independent. Ship (1) first: no migration, immediate value."

### A2. Optional input (Rule 3 — nullable-first, never make the user fill fields)

- **List every new field/column.** For each: **is it nullable? (yes/no)** If **no**,
  write the specific reason it must be mandatory — "it felt required" is not a reason.
  Default is nullable.
- **Confirm the floor still works:** does the simplest existing flow (e.g. a bare
  free-text calorie record with nothing else filled in) keep working *unchanged*?
- **For each new field, what happens when it's absent?** Must degrade silently — omit
  from rollups, hide the section. Never block, badge, or nag.
- **What gets prefilled, and from where?** (locale → currency, last-used → new entry.)
  The user should never type a code or repeat a value they've already given.
- **At what level does each piece of data attach?** Enter-once, reuse-everywhere:
  price on the product (not per record), rating on the meal (not per ingredient).

> Good answer example: "New fields: product.priceMinor (nullable — user may not know
> the price), record.costMinor (nullable snapshot). Absent price → cost section hidden,
> no badge. Currency prefilled from device locale. Floor: a plain calorie record with
> no product still saves fine."

### A3. Editability (Rule 4 — every value stays editable)

- **List every user-entered OR auto-set value** the feature introduces (timestamps,
  weights, prices, ratings, titles, grouping, completion stamps).
- **For EACH: through which normal UI screen can the user change it later?** Deleting
  and re-creating does not count. If you can't name a screen, the design is missing one.
- **Any snapshotted/denormalized value?** (e.g. cost frozen on a record at event time.)
  For each, state explicitly which you provide: **direct edit of the snapshot**, a
  **"recompute from current source" action**, or both.
- **Any auto-set value?** (e.g. `eatenAt` stamped on completion.) Name its obvious
  undo/clear path (`setUncompleted`-style), not just its setter.

> Good answer example: "Editable: price (product edit sheet), record cost (record edit
> sheet — direct edit of snapshot, plus 'reset to current product price'). Auto-set:
> eatenAt on complete → cleared via setUncompleted."

---

## Step B — Write the plan document (Rule 2 — plans are always markdown files)

Never leave the design only in chat. Write it to a file and keep editing that file as
the design iterates — the file is the artifact, chat is not.

- **Draft** in `.stuff/<topic>_plan.md` (gitignored working notes).
- **Once agreed**, promote it to `docs/plans/<topic>_plan.md` and commit. A promoted
  plan must **not** reference `.stuff/` paths — they don't exist in the repo.
- When plans merge or supersede each other, write the union as a **new** doc and leave
  the originals for the user to delete.

The document must contain these sections, in order:

1. **What already exists to build on** — concrete file paths in the current codebase.
2. **Data-model sketch** — new/changed tables and fields, each marked nullable or not
   (carry over your A2 answers).
3. **UX flows** — the screens and how data is entered/edited (carry over A3).
4. **Increment roadmap** — the ordered list + the ASCII dependency graph from A1.
5. **Non-goals** — an explicit list of what this design deliberately does NOT do, to
   protect its constraints from scope creep.

---

## Final check before you present the plan

Answer yes to all four or go back:

- [ ] Every increment leaves the app fully working on its own (A1).
- [ ] Every new field is nullable, or has a written reason it can't be (A2).
- [ ] Every value has a named edit path; snapshots state edit-vs-recompute (A3).
- [ ] The plan is a markdown file with all five sections, not just chat output (B).
