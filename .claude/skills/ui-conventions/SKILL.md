---
name: ui-conventions
description: Visual consistency and structure rules for building or editing Flutter UI in the Cat Calories app. Use whenever creating or changing a widget, card, sheet, button, navigation bar, or any visual component. Covers reusing the shared widget catalogue (AppCard, MacroBadges, ErrorDisplay, calculator sheets, etc.), using squircles (ContinuousRectangleBorder) instead of rounded-rectangle corners on rectangular shapes, checking spacing/curvature symmetry, and keeping widgets small (~200-line cap, split into sub-widget classes).
---

# UI conventions

The full, tool-agnostic guide — the shared-component catalogue, the squircle rule, and
the symmetry checklist with worked examples — lives in
[docs/ui-conventions.md](../../../docs/ui-conventions.md). Read it before building UI.

Three rules, quick reference:

1. **Reuse shared components** from `lib/common/widgets/` — `AppCard` for cards,
   `MacroBadgesRow` for P/F/C, `ErrorDisplay`/`ErrorStateWidget` for errors,
   `CalculatorSheet` & co. for calculators, `ModeButton`, `ProgressPainter`. Don't
   hand-roll a `Container`-card when `AppCard` exists. (`common/widgets/**` must stay
   feature-agnostic — no `features/**` imports.)
2. **Squircles, not rounded rectangles.** For any square/rectangular surface use
   `AppCard.squircleBorder(radius:)` (a `ContinuousRectangleBorder`), not
   `BorderRadius.circular(...)`. Truly circular shapes (avatars, `MacroCircle`) stay
   circles. Note: theme + a few widgets aren't converted yet — convert when you touch
   them, don't add new circular corners on rectangles.
3. **Check symmetry.** Equal horizontal/vertical padding; equal margins from screen
   edges; for nested shapes, a uniform gap on all sides and concentric corners
   (`inner_radius ≈ outer_radius − gap`). Good reference:
   `indicators_widget.dart`. Known offender: `home_bottom_nav.dart`.
4. **Keep widgets small** — ~200-line soft cap per widget. Past that, extract sub-widget
   *classes* (`class _Foo extends StatelessWidget`), not `_buildX()` helper methods.
   `home_bottom_nav.dart` (`_HomeBottomNavTile`) is the pattern to follow.

Details, before/after snippets, and the symmetry checklist:
[docs/ui-conventions.md](../../../docs/ui-conventions.md).
