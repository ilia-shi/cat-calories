---
name: code-comments
description: Commenting convention for the Cat Calories codebase. Use whenever writing or editing Dart/TypeScript code and deciding whether to add a comment or doc comment. The rule: do NOT narrate what the code already says; only comment things that carry information the reader cannot get from the code itself — TODO/FIXME, and warnings about performance, user-experience, correctness pitfalls, or non-obvious external constraints.
---

# Code comments

Default to **no comment**. Well-named code is the documentation. A comment must earn
its place by carrying information the reader cannot recover by reading the code.

## Don't write these

- **Narration** that restates the code. If the comment is a paraphrase of the line
  below it, delete it.
- **Doc comments that just describe what a class/method obviously does** ("Compact
  search field that opens a search page…"). The name and signature already say this.
- **Section banners** (`// build the row`), obvious step labels, and change-log notes
  (`// added search`). Git history covers the last one.

```dart
// BAD — narrates the code
// Re-read the latest state from the bloc
final state = context.read<HomeBloc>().state;

// BAD — restates the obvious
// Loop over products and filter by query
for (final product in products) { ... }
```

## Do write these

Comment only when the *why* is non-obvious or the reader would otherwise get it wrong:

- **`TODO:` / `FIXME:`** — known gaps, follow-ups, temporary code. Keep them actionable.
- **Performance** — why something is batched, cached, debounced, or done off the main
  isolate; an O(n²) that's intentional; a rebuild avoided on purpose.
- **User experience** — a deliberate delay, an intentionally-swallowed error, an edge
  case that would otherwise flicker/jump/lose input.
- **Correctness pitfalls & non-obvious constraints** — ordering that must not change,
  a workaround for an upstream/framework bug (link it), an invariant callers must hold,
  units/ranges that aren't in the type.

```dart
// GOOD — a constraint the reader can't see
// sortOrder must be applied before the category filter; the DB index depends on it.

// GOOD — external cause + why the workaround exists
// Framework bug flutter/flutter#12345: BackdropFilter needs a ClipRect ancestor
// or it repaints the whole screen. Remove when we bump past 3.3x.

// FIXME: recomputes on every keystroke; move filtering into the repository if the
// product list grows past a few hundred.
```

## Test

Before keeping a comment, ask: *"If I delete this, does the reader lose information the
code doesn't already give them?"* If no, delete it. If the answer is "they'd lose the
**why**, a **risk**, or a **TODO**", keep it — and make sure it says that, not the what.
