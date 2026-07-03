---
name: ui-conventions
description: Visual consistency and structure rules for building or editing Flutter UI in the Cat Calories app. Use whenever creating or changing a widget, card, sheet, button, navigation bar, or any visual component. Covers reusing the shared widget catalogue (AppCard, MacroBadges, ErrorDisplay, calculator sheets, etc.), using squircles (ContinuousRectangleBorder) instead of rounded-rectangle corners on rectangular shapes, checking spacing/curvature symmetry, and keeping widgets small (~200-line cap, split into sub-widget classes). Do NOT use for non-visual logic, data-layer, or server changes.
---

# UI conventions

**Before building or editing UI, read [docs/ui-conventions.md](../../../docs/ui-conventions.md)**
for the before/after snippets and worked symmetry examples. This skill inlines the rules
you must not break, so that even without re-reading the doc your widget stays consistent.

## Rule 1 — Reuse shared components (don't hand-roll)

Before writing a `Container` + `BoxDecoration`, check whether a shared widget already
exists in `lib/common/widgets/`. Common mappings:

| If you're building… | Use this instead |
|---|---|
| Card / elevated surface | `AppCard` (`common/widgets/app_card.dart`) |
| The squircle shape on any rectangular surface | `AppCard.squircleBorder(radius:)` |
| P/F/C macro indicators | `MacroCircle` / `MacroBadge` / `MacroBadgesRow` |
| Progress rendering | `ProgressPainter` |
| Toggle / segmented button | `ModeButton` |
| Calculator sheet + keypad | `CalculatorSheet`, `CalculatorKeypad`, `CalcKeyButton`, `CalculatorFieldDisplay` |
| Full-screen / inline error state | `ErrorStateWidget` / `InlineErrorWidget` |
| Snackbar / toast / error dialog | `ErrorDisplay.showError/showWarning/showSuccess` |

Read colours via `AppColors.of(context)`; frosted-surface constants via
`CustomTheme.surfaceBlurSigma` / `surfaceOpacity`. **Boundary:** `common/widgets/**`
must not import any `features/**` — if a widget is only meaningful to one feature, keep
it under that feature.

## Rule 2 — Squircles, not rounded rectangles

For **any square/rectangular surface** (cards, sheets, pills, bars, badges, buttons,
tiles) use a squircle — `AppCard.squircleBorder(radius:)`, a `ContinuousRectangleBorder`
— **never** `BorderRadius.circular(...)` / `RoundedRectangleBorder`.

```dart
// ✗ avoid — circular corners on a rectangular surface
Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)))

// ✓ prefer — squircle via the shared helper
DecoratedBox(decoration: ShapeDecoration(shape: AppCard.squircleBorder(radius: 16)))
```

- **Truly circular** shapes (avatars, `MacroCircle`, round FAB) stay circles — the rule
  is about rectangular shapes, not banning roundness.
- For clipping/ripples, derive the clip/`customBorder` from the **same**
  `squircleBorder(...)` so surface, ink, and clip share one shape.
- **Migration gap:** `common/theme/theme.dart` and a few widgets still use
  `BorderRadius.circular`. Convert them when you touch them; never add new circular
  corners on rectangles.

## Rule 3 — Check symmetry

- Horizontal padding == vertical padding (or deliberately, consistently related).
- Equal gaps between repeated items; equal margins from screen left/right/top.
- For a shape nested in another: uniform gap on **all four** sides, and
  `inner_radius ≈ outer_radius − gap` so corners stay concentric.

Good reference: `indicators_widget.dart` (uniform `12` gap everywhere). Known offender:
`home_bottom_nav.dart` (pill inset `7` vertical but a *fraction* horizontally → uneven
gap; bar radius `22` vs pill `14` → non-concentric). The doc explains the fix.

## Rule 4 — Keep widgets small (~200-line soft cap)

Past ~200 lines, extract sub-widget **classes**, not `_buildX()` helper methods:

```dart
// ✓ focused widget class — const constructor, rebuilds independently
class _IndicatorCard extends StatelessWidget { const _IndicatorCard({...}); ... }

// ✗ build-method helper — grows the parent, no const, rebuilds with it
Widget _buildIndicatorCard({...}) { ... }
```

`home_bottom_nav.dart` (`_HomeBottomNavTile`) is the pattern to follow. First extract
`_Foo` classes in the same file; once the file is large, move them to
`lib/features/<feature>/ui/widgets/`.

## Final checklist — answer before claiming the widget done

- [ ] No hand-rolled duplicate of a shared component from Rule 1's table.
- [ ] No `BorderRadius.circular` / `RoundedRectangleBorder` on a rectangular surface.
- [ ] Colours via `AppColors.of(context)`, not hard-coded greys.
- [ ] Symmetric padding; nested shapes have uniform gaps + concentric corners.
- [ ] Each widget class is under ~200 lines (or sub-widgets already extracted).
- [ ] `flutter analyze` is clean.

For a mechanical grep-driven audit of a finished widget, use the `review-ui` skill.
