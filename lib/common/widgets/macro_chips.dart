import 'package:flutter/material.dart';
import 'package:cat_calories/common/theme/colors.dart';

/// The colored circle holding a macro letter ('P', 'F', 'C').
class MacroCircle extends StatelessWidget {
  final String label;
  final Color color;
  final bool hasData;

  const MacroCircle({
    Key? key,
    required this.label,
    required this.color,
    this.hasData = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appColors = AppColors.of(context);
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: appColors.macroCircleBg(color, hasData),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: appColors.macroCircleText(color, hasData),
          ),
        ),
      ),
    );
  }
}

/// A single macronutrient indicator: [MacroCircle] followed by the value
/// in grams. Renders an em dash when the value is null.
class MacroBadge extends StatelessWidget {
  final String label;
  final double? value;
  final Color color;

  const MacroBadge({
    Key? key,
    required this.label,
    required this.value,
    required this.color,
  }) : super(key: key);

  const MacroBadge.protein({Key? key, required this.value})
      : label = 'P',
        color = MacroProteinColor,
        super(key: key);

  const MacroBadge.fat({Key? key, required this.value})
      : label = 'F',
        color = MacroFatColor,
        super(key: key);

  const MacroBadge.carbs({Key? key, required this.value})
      : label = 'C',
        color = MacroCarbColor,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    final appColors = AppColors.of(context);
    final hasData = value != null;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        MacroCircle(label: label, color: color, hasData: hasData),
        const SizedBox(width: 4),
        Text(
          hasData ? '${value!.round()}g' : '—',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: appColors.macroValueText(hasData),
          ),
        ),
      ],
    );
  }
}

/// The standard P/F/C badge trio, with an optional leading kcal value.
/// Scales down to fit when the parent is narrower than the badges.
class MacroBadgesRow extends StatelessWidget {
  final double? calories;
  final double? protein;
  final double? fat;
  final double? carbs;

  const MacroBadgesRow({
    Key? key,
    this.calories,
    this.protein,
    this.fat,
    this.carbs,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appColors = AppColors.of(context);
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (calories != null) ...[
            Text(
              '${calories!.round()} kcal',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: appColors.tintedText(MacroFatColor),
              ),
            ),
            const SizedBox(width: 12),
          ],
          MacroBadge.protein(value: protein),
          const SizedBox(width: 12),
          MacroBadge.fat(value: fat),
          const SizedBox(width: 12),
          MacroBadge.carbs(value: carbs),
        ],
      ),
    );
  }
}
