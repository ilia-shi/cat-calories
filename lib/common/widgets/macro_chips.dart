import 'package:flutter/material.dart';
import 'package:cat_calories/common/theme/colors.dart';

/// The colored circle holding a macro letter ('P', 'F', 'C') or an [icon].
class MacroCircle extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color color;
  final bool hasData;

  const MacroCircle({
    Key? key,
    required this.label,
    this.icon,
    required this.color,
    this.hasData = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appColors = AppColors.of(context);
    if (icon != null) {
      return Icon(
        icon,
        size: 16,
        color: appColors.tintedText(color),
      );
    }
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
  final IconData? icon;
  final double? value;
  final Color color;
  final String unit;

  const MacroBadge({
    Key? key,
    required this.label,
    this.icon,
    required this.value,
    required this.color,
    this.unit = 'g',
  }) : super(key: key);

  const MacroBadge.protein({Key? key, required this.value})
      : label = 'P',
        icon = null,
        color = MacroProteinColor,
        unit = 'g',
        super(key: key);

  const MacroBadge.fat({Key? key, required this.value})
      : label = 'F',
        icon = null,
        color = MacroFatColor,
        unit = 'g',
        super(key: key);

  const MacroBadge.carbs({Key? key, required this.value})
      : label = 'C',
        icon = null,
        color = MacroCarbColor,
        unit = 'g',
        super(key: key);

  const MacroBadge.calories({Key? key, required this.value})
      : label = '',
        icon = Icons.local_fire_department,
        color = MacroCaloriesColor,
        unit = '',
        super(key: key);

  @override
  Widget build(BuildContext context) {
    final appColors = AppColors.of(context);
    final hasData = value != null;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        MacroCircle(
          label: label,
          icon: icon,
          color: color,
          hasData: hasData,
        ),
        const SizedBox(width: 4),
        Text(
          hasData ? '${value!.round()}$unit' : '0',
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
