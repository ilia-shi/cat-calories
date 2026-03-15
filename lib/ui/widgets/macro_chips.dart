import 'package:flutter/material.dart';
import 'package:cat_calories/ui/colors.dart';

/// A compact chip widget displaying a macronutrient label and value
class MacroChip extends StatelessWidget {
  final String label;
  final double? value;
  final Color color;
  final bool compact;

  const MacroChip({
    Key? key,
    required this.label,
    required this.value,
    required this.color,
    this.compact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _buildCompact(context);
    }
    return _buildNormal(context);
  }

  Widget _buildNormal(BuildContext context) {
    final appColors = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: appColors.tintedSurface(color),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            value != null ? '${value!.toStringAsFixed(1)}g' : '-',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: appColors.tintedText(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompact(BuildContext context) {
    final appColors = AppColors.of(context);
    return Text(
      '$label: ${value?.toStringAsFixed(0) ?? '-'}',
      style: TextStyle(
        fontSize: 11,
        color: appColors.tintedText(color),
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

/// A row of macronutrient chips that wraps to prevent overflow
class MacrosRow extends StatelessWidget {
  final double? calories;
  final double? protein;
  final double? fat;
  final double? carbs;
  final bool showCalories;
  final bool compact;

  const MacrosRow({
    Key? key,
    this.calories,
    this.protein,
    this.fat,
    this.carbs,
    this.showCalories = true,
    this.compact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _buildCompactRow(context);
    }
    return _buildChipRow(context);
  }

  Widget _buildChipRow(BuildContext context) {
    final appColors = AppColors.of(context);
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        if (showCalories && calories != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: appColors.tintedSurface(Colors.orange),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${calories!.toStringAsFixed(0)} kcal',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: appColors.tintedText(Colors.orange),
              ),
            ),
          ),
        MacroChip(label: 'P', value: protein, color: MacroProteinColor),
        MacroChip(label: 'F', value: fat, color: MacroFatColor),
        MacroChip(label: 'C', value: carbs, color: MacroCarbColor),
      ],
    );
  }

  Widget _buildCompactRow(BuildContext context) {
    final appColors = AppColors.of(context);
    return Wrap(
      spacing: 6,
      runSpacing: 2,
      children: [
        if (showCalories && calories != null)
          Text(
            '${calories!.toStringAsFixed(0)} kcal',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: appColors.tintedText(Colors.orange),
            ),
          ),
        MacroChip(label: 'P', value: protein, color: MacroProteinColor, compact: true),
        MacroChip(label: 'F', value: fat, color: MacroFatColor, compact: true),
        MacroChip(label: 'C', value: carbs, color: MacroCarbColor, compact: true),
      ],
    );
  }
}

/// A simple inline macro display for very compact spaces
class MacrosInline extends StatelessWidget {
  final double? protein;
  final double? fat;
  final double? carbs;

  const MacrosInline({
    Key? key,
    this.protein,
    this.fat,
    this.carbs,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appColors = AppColors.of(context);
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: 'P: ${protein?.toStringAsFixed(0) ?? '-'} ',
            style: TextStyle(fontSize: 11, color: appColors.tintedText(MacroProteinColor)),
          ),
          TextSpan(
            text: 'F: ${fat?.toStringAsFixed(0) ?? '-'} ',
            style: TextStyle(fontSize: 11, color: appColors.tintedText(MacroFatColor)),
          ),
          TextSpan(
            text: 'C: ${carbs?.toStringAsFixed(0) ?? '-'}',
            style: TextStyle(fontSize: 11, color: appColors.tintedText(MacroCarbColor)),
          ),
        ],
      ),
    );
  }
}