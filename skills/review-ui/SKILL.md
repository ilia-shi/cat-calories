---
name: review-ui
description: Verify UI design correctness by static code analysis — no app launch needed. Use after building or editing any Flutter widget to confirm it follows the Cat Calories visual conventions (squircles, transparent surfaces, AppColors tokens, compact spacing, shared components). Returns a checklist verdict with specific file:line callouts for any violations.
---

# UI design review — static analysis

Review changed Flutter UI files for visual-convention compliance without running the app.
Work through the checklist below; for each item read the relevant widget source and report
**PASS / FAIL / N/A** with a `file:line` citation for every FAIL.

## What to review

Default scope: files changed since the last commit.

```bash
git diff HEAD --name-only | grep '\.dart$'
```

If the user names specific files, review those instead.

## Checklist

### 1. Squircles — no `BorderRadius.circular` on rectangular surfaces

Search every changed file for rounded-rectangle corners:

```bash
grep -n "BorderRadius\.\(circular\|only\|horizontal\|vertical\)" <file>
grep -n "RoundedRectangleBorder" <file>
```

**PASS** — none found, or only on truly circular shapes (avatars, `MacroCircle`).  
**FAIL** — cite the line; the fix is `AppCard.squircleBorder(radius: …)` wrapped in `ShapeDecoration`.

### 2. Transparent / theme-token surfaces — no hard-coded grey backgrounds

Changed widgets should use `AppColors` tokens, not hard-coded colours:

```bash
grep -n "Colors\.grey\|Color(0x\|Color(#" <file>
```

For container backgrounds specifically look for `Colors.grey[…]` or `Colors.white`/`Colors.black` as `color:` values.  
**PASS** — backgrounds use `appColors.surfaceSubtle`, `appColors.surface`, or similar tokens.  
**FAIL** — cite the line; fix is `AppColors.of(context).<token>`.

### 3. TextField fill — transparent when inside a shaped container

If the file contains a `TextField` inside a shaped `Container` / `DecoratedBox`:

```bash
grep -n "TextField\|filled:\|fillColor:\|InputDecoration" <file>
```

**PASS** — `filled: true` + `fillColor: Colors.transparent` + all border variants set to `InputBorder.none`.  
**FAIL** — any missing item; cite the line. A TextField without these will paint its own opaque fill over the outer squircle.

### 4. Shared components — no hand-rolled duplicates

Check that the widget doesn't re-implement something already in `lib/common/widgets/`:

| If the widget does… | Should use |
|---|---|
| Card / elevated surface | `AppCard` |
| P/F/C macro indicators | `MacroBadgesRow` / `MacroBadge` |
| Calculator display field | `CalculatorFieldDisplay` |
| Calculator sheet chrome | `CalculatorSheet` |
| Numeric keypad | `CalculatorKeypad` |
| Error state | `ErrorStateWidget` / `InlineErrorWidget` |
| Snackbar / toast | `ErrorDisplay.showError/showSuccess` |

```bash
grep -n "Container\|BoxDecoration\|Column\|Row" <file> | head -30
```

**PASS** — no obvious hand-rolled duplicate of a shared component.  
**FAIL** — cite the block; suggest the shared component to use instead.

### 5. Spacing symmetry

Scan for `EdgeInsets` values in the file:

```bash
grep -n "EdgeInsets\|SizedBox\|padding\|margin" <file>
```

**PASS** — horizontal and vertical padding values are equal or intentionally related; equal gaps between sibling items; for nested shapes `inner_radius ≈ outer_radius − gap`.  
**WARN** — asymmetric values that look accidental (e.g. `top:7, bottom:7` but horizontal derived differently). Cite and flag for human review.

### 6. Widget size — ~200-line soft cap

```bash
wc -l <file>
```

**PASS** — under 200 lines, or sub-widget classes already extracted.  
**WARN** — over 200 lines; note the count and suggest extracting the largest `_buildX` method into a widget class.

---

## Output format

```
## UI Design Review

**Files reviewed:** <list>

| Check | Result | Notes |
|---|---|---|
| Squircles | ✅ PASS / ❌ FAIL | file:line — description |
| Transparent surfaces | ✅ / ❌ | … |
| TextField fill | ✅ / ❌ / N/A | … |
| Shared components | ✅ / ❌ | … |
| Spacing symmetry | ✅ / ⚠️ WARN | … |
| Widget size | ✅ / ⚠️ WARN | … |

### Violations
<one line per FAIL/WARN with exact file:line and the fix>

**Overall:** PASS (all green) | FAIL (n violations) | WARN (no hard failures, n warnings)
```

If there are no violations, say so in one line and stop — don't pad the output.
