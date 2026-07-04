---
name: refactor
description: Discipline for behavior-preserving refactors in the Cat Calories codebase — splitting an oversized widget or file into smaller widgets/classes, extracting logic into a controller, or reorganizing code without changing what it does. Use whenever asked to refactor, split, extract, break up, or clean up the structure of existing code (as opposed to adding a feature or fixing a bug). Its central rule: when you move code, do NOT carry its comments along blindly — re-judge every one against the code-comments convention and drop the ones that no longer earn their place. Do NOT use for behavior changes, new features, or bug fixes.
---

# Refactoring

A refactor changes structure, not behavior. Same inputs, same outputs, same side effects —
only the shape of the code improves. If you find yourself wanting to fix a bug or change UX
mid-refactor, stop and surface it separately; don't smuggle it into a "cleanup".

## Rule 1 — Don't transfer comments unthinkingly

This is the rule refactors break most often. When you cut a block of code and paste it into a
new widget, method, or file, **every comment that rides along must re-earn its place** against
the [code-comments](../code-comments/SKILL.md) convention in its new home.

Moving code changes what the reader can already see, so a comment that was borderline before is
often pure noise after:

- **Section banners and step labels** (`// Time`, `// Description`, `// Expanded Items`,
  `// Total Calories`) almost never survive extraction — once the block becomes a well-named
  widget or method, the name says it. Delete them.
- **Narration** that restated the old surrounding context (`// Show macros in bottom sheet
  preview`) is even more redundant next to a `CalorieRecordMacros(item: item)` call. Delete it.
- **Why / risk / constraint / TODO** comments must survive the move. If a comment explains an
  ordering that must not change, a swallowed error, a framework workaround, or an invariant,
  carry it — and keep it attached to the exact line it guards.

Before pasting, ask the code-comments test for each comment: *"in this new location, does the
reader lose the why, a risk, or a TODO if I delete it?"* If not, drop it.

```dart
// BEFORE — inline in a 600-line build method, banners helped scanning
Row(children: [
  // Time
  Container(width: 56, ...),
  // Color indicator
  Container(width: 4, ...),
])

// AFTER — extracted to CalorieRecordRow; the banners are noise, delete them
Row(children: [
  _TimeColumn(item: item),
  Container(width: 4, ...),
])
```

## Rule 2 — Preserve behavior exactly

- Move code verbatim first; clean it up second. Don't rename, re-order, or "improve" logic in
  the same edit that relocates it — you lose the ability to tell a move from a change.
- Watch for **silent visual/behavior drift**: swapping a raw `Color.withValues(alpha: 0.1)` for
  an `AppColors` token, a `StatefulBuilder` for a `StatefulWidget`, or a default parameter can
  subtly change output. If you make such a change deliberately, call it out to the user; never
  let it slip in unmentioned.
- Keep controller/widget seams honest: extracted presentational widgets take **data in and
  callbacks out** — no repositories, navigation, snackbars, or bloc access. Pure logic pulled
  into a controller takes **no `BuildContext`** so it stays testable.

## Rule 3 — Work in small, compiling steps

Big refactors land as a sequence of independently-verifiable steps, not one giant edit:

1. Extract the leaf pieces first (pure presentational widgets, no callbacks into logic).
2. Then modals/dialogs, then composite widgets, then the logic/controller layer.
3. After each step: remove now-dead imports and dead private members, then run
   `flutter analyze` on the touched files and `make arch` if imports crossed layers.

See [ui-conventions](../ui-conventions/SKILL.md) for the ~200-line widget cap and the
"split into sub-widget classes" pattern that drives most widget refactors.

## Rule 4 — Delete what you replaced

A refactor that leaves the old method/class/import behind is half-done and worse than none —
now there are two of everything. After redirecting call sites to the new home, delete the
originals and let the analyzer confirm nothing else referenced them.

## Verify

`flutter analyze` clean on every touched file, `make arch` clean for cross-layer moves, and —
if you extracted logic into a controller or pure function — a unit test that exercises it, since
making that logic testable is usually the point of the extraction. Behavior is unchanged, so
existing tests must still pass without modification.
