import 'package:cat_calories/common/widgets/macro_chips.dart';
import 'package:cat_calories/features/calorie_tracking/ui/widgets/calorie_record_row.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/meal_totals.dart';
import 'package:flutter/material.dart';

/// A meal's summed macros, with its total weight and cost trailing them — the
/// same strip a single record shows, one level up.
///
/// Always one line: macros, weight and cost belong to the same reading, so a
/// narrow header scales the whole strip down rather than breaking it up.
///
/// Renders nothing when no ingredient carries a macro, so a meal logged as bare
/// calories doesn't grow a row of zeroes.
class MealTotalsStrip extends StatelessWidget {
  /// Gap between the macro badges and each trailing fact.
  static const double _gap = 10;

  final MealTotals totals;

  /// Which edge the strip hugs once it has been scaled down to fit.
  final AlignmentGeometry alignment;

  const MealTotalsStrip({
    Key? key,
    required this.totals,
    this.alignment = Alignment.centerLeft,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!totals.hasMacros) {
      return const SizedBox.shrink();
    }

    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: alignment,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          MacroBadgesRow(
            protein: totals.protein,
            fat: totals.fat,
            carbs: totals.carbs,
          ),
          if (totals.hasWeight) ...[
            const SizedBox(width: _gap),
            MacroStripFact(
              icon: Icons.scale,
              label: '${totals.weightGrams.round()}g',
            ),
          ],
          for (final cost in totals.costs.entries) ...[
            const SizedBox(width: _gap),
            MacroStripFact(
              icon: Icons.payments_outlined,
              label: '${cost.value.toStringAsFixed(2)} ${cost.key}',
            ),
          ],
        ],
      ),
    );
  }
}
