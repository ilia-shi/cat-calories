# UI conventions — Cat Calories

Visual consistency rules for the Flutter app (`lib/`). Apply these whenever you build
or edit a widget. Three rules: **reuse shared components**, **squircles not rounded
rectangles**, and **check symmetry**.

## 1. Reuse the shared components

Before building any common UI element, check `lib/common/widgets/` first — wrap or
extend what exists instead of re-implementing. The shared catalogue:

| Component | File | Use for |
|-----------|------|---------|
| `AppCard` | `common/widgets/app_card.dart` | **Any card / elevated surface.** Handles squircle shape, shadow, optional `onTap`, gradient, `emphasized`. Don't hand-roll a `Container` + `BoxDecoration` card. |
| `AppTopBar`, `AppTopBarAction`, `AppTopBarTextAction` | `common/widgets/app_top_bar.dart` | **Every screen's app bar.** Flat transparent bar, squircle back button (auto-shown when the route can pop), centred title, squircle pill actions. Never pass a bare `AppBar` to `Scaffold.appBar`. |
| `AppCard.squircleBorder(...)` | same | The squircle `ShapeBorder` helper — reuse it for *any* rectangular surface (sheets, pills, bars), not just cards. See rule 2. |
| `MacroCircle`, `MacroBadge`, `MacroBadgesRow` | `common/widgets/macro_chips.dart` | Protein/Fat/Carb indicators (the P/F/C circles + gram values). |
| `ProgressPainter` | `common/widgets/progress_bar.dart` | Custom progress rendering. |
| `ModeButton` | `common/widgets/mode_button.dart` | Toggle / segmented-style buttons. |
| `CalculatorSheet`, `CalculatorKeypad`, `CalcKeyButton`, `CalculatorFieldDisplay` | `common/widgets/calculator/` | Frosted bottom-sheet calculator chrome + keypad. |
| `NutritionCalculatorWidget`, `CalculatorWidget` | `common/widgets/` | Nutrition / numeric entry calculators. |
| `ErrorStateWidget`, `InlineErrorWidget` | `common/widgets/error_state_widget.dart` | Full-screen / inline error states. |
| `ErrorDisplay` | `common/widgets/error_display.dart` | Imperative `showError` / `showWarning` / `showSuccess` snackbars + error dialogs. |

Theme tokens live in `lib/common/theme/`: read colors via `AppColors.of(context)`, and
frosted-surface constants via `CustomTheme.surfaceBlurSigma` / `surfaceOpacity`.

**Boundary note:** `common/widgets/**` must stay feature-agnostic — it must not import
any `features/**` (enforced by `import_lint`). If a widget is only meaningful to one
feature, keep it under that feature; only promote genuinely reusable, feature-free
widgets into `common/widgets/`. See [architecture.md](architecture.md).

## 2. Squircles, not rounded rectangles

For **any square or rectangular shape** (cards, sheets, pills, bars, badges, buttons,
tiles), use a **squircle** — a `ContinuousRectangleBorder` — never a
`RoundedRectangleBorder` / `BorderRadius.circular(...)` corner. The canonical helper is
in `app_card.dart`:

```dart
// app_card.dart — the project squircle. Note the 1.5x scale: a ContinuousRectangleBorder
// needs a larger radius than a circular one to read as the same visual roundness.
static const double _squircleScale = 1.5;
static ContinuousRectangleBorder squircleBorder({
  double radius = defaultBorderRadius,
  bool top = true,
  bool bottom = true,
  BorderSide side = BorderSide.none,
  squircleScale = _squircleScale,
}) { ... }
```

Use it:

```dart
// ✗ avoid — circular corners on a rectangular surface
Container(
  decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), ...),
)

// ✓ prefer — squircle via the shared helper
DecoratedBox(
  decoration: ShapeDecoration(shape: AppCard.squircleBorder(radius: 16), ...),
)
```

- **Truly circular** shapes (avatars, the P/F/C `MacroCircle`, a round FAB) stay
  circles — the rule is about *square/rectangular* shapes, not banning roundness.
- Tiny pill-shaped tags can read fine either way, but prefer the squircle for
  consistency when in doubt.
- For clipping and ripples, derive the clip/`customBorder` from the **same**
  `squircleBorder(...)` so the surface, ink, and clip all share one shape (see how
  `AppCard.build` reuses `shape` for the `Material`, `InkWell`, and `ShapeDecoration`).

**Known migration gap:** not everything is converted yet. `lib/common/theme/theme.dart`
(card/sheet/dialog/button themes) and some widgets — e.g. the progress-bar and the
small `%` chip in `indicators_widget.dart` — still use `BorderRadius.circular(...)`.
Treat these as squircle-conversion candidates when you touch them; don't add new
`BorderRadius.circular` on rectangular surfaces.

## 3. Check symmetry

A component reads as "clean" when its spacing and curvature are symmetric. Two things to
verify on every component:

**a) Equal spacing.** Horizontal and vertical paddings/gaps should match (or be
deliberately, consistently related). Distances from the screen's left, right, and top
edges should be equal.

**b) Concentric curvature for nested shapes.** When a rounded/squircle shape sits inside
another (a pill inside a bar, content inside a card), keep the gap uniform on all four
sides, and make the inner radius track the outer one:

```
inner_radius ≈ outer_radius − gap
```

so the corners stay concentric and the gap doesn't visually pinch or bulge at corners.

### Good example — `indicators_widget.dart`

Cards are laid out with a uniform `12` gap everywhere: between the two top cards
(`SizedBox(width: 12)`), between the rows (`SizedBox(height: 12)`), and between the
compact cards. Combined with equal outer margins, every card sits an equal distance from
its neighbours and from the screen edges. That uniformity is what makes it look
balanced.

### Bad example — `home_bottom_nav.dart`

The sliding pill inside the bar is **not** symmetric:

- **Unequal padding.** The pill is inset `top: 7, bottom: 7` (vertical = 7px), but its
  horizontal inset is derived from a *fraction* of the slot
  (`pillFraction = 0.74` → horizontal inset ≈ `slotWidth * 0.13`), which does not equal
  7px. The gap around the pill is therefore different horizontally vs. vertically.
- **Non-concentric curvature.** Bar radius is `22`, pill radius is `14`. With a 7px gap
  the concentric inner radius would be `22 − 7 = 15`, and that only holds if the gap is
  7px on *all* sides — which it isn't (see above). So the pill's corners don't run
  parallel to the bar's corners; the distance between the two curves varies along the
  shape.

**How to fix this class of problem:** pick one inset value and apply it on all four
sides (derive `pillWidth` from a fixed inset, not a fraction), then set the inner radius
to `outerRadius − inset` so the curves stay concentric. The same check applies to any
nested-shape layout.

### Symmetry checklist

- [ ] Horizontal padding == vertical padding (or intentionally, consistently related)?
- [ ] Equal gaps between repeated items, and equal margins from screen left/right/top?
- [ ] For nested shapes: uniform gap on all four sides?
- [ ] For nested shapes: `inner_radius ≈ outer_radius − gap` (concentric corners)?

## 4. Keep widgets small — split at ~200 lines

Don't let a widget inflate. **~200 lines is the soft cap** for a single widget class (or
file). When a `build` method or file grows past that, extract the parts into smaller
widgets, each with one clear responsibility.

**Extract widget *classes*, not `_buildX` methods.** Prefer:

```dart
// ✓ a focused widget — const constructor, rebuilds independently, easy to read/test
class _IndicatorCard extends StatelessWidget {
  const _IndicatorCard({required this.title, required this.value, ...});
  ...
  @override
  Widget build(BuildContext context) { ... }
}
```

over a private helper that returns a `Widget`:

```dart
// ✗ a build-method helper — grows the parent, rebuilds with it, no const, harder to scan
Widget _buildIndicatorCard({required String title, required double value, ...}) { ... }
```

Widget classes give better rebuild isolation (a `const` child skips rebuilds when the
parent changes) and keep each class short. `home_bottom_nav.dart` does this well — it
splits `_HomeBottomNavTile` into its own widget rather than a `_buildTile()` method.

**How to split:**

- First extract private `_Foo` widget classes in the same file.
- Once the file itself gets large, move them to separate files — e.g. a `widgets/`
  subfolder within the feature (`lib/features/<feature>/ui/widgets/`).
- Pull pure layout/format helpers into plain functions or `common/utils`.

**Current over-budget files** (refactor candidates when you touch them):
`edit_profile_screen.dart` (~1365), `servers_screen.dart` (~1188),
`calories_history.dart` (~1153), `app_bar.dart` (~985), `products_tab.dart` (~954). Even
the symmetry reference `indicators_widget.dart` (~480) exceeds the cap and leans on
`_buildIndicatorCard` / `_buildCompactIndicator` methods — those should become widget
classes.

200 is a guideline, not a hard gate — cohesion matters more than the exact count — but
treat crossing it as a prompt to ask "what sub-widget is hiding in here?"

## Verify

`flutter analyze` after changes. There's no automated visual check — review against the
checklists above, and compare with `indicators_widget.dart` as the reference for good
*spacing* (not for file size). To spot oversized widgets:

```bash
find lib/features -name "*.dart" -path "*/ui/*" | xargs wc -l | sort -rn | head
```

See [testing.md](testing.md) for the rest of the verification matrix.
