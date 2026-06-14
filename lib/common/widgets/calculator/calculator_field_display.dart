import 'package:cat_calories/common/theme/colors.dart';
import 'package:cat_calories/common/widgets/app_card.dart';
import 'package:flutter/material.dart';

/// The large bordered "current value" card shown above a [CalculatorKeypad].
///
/// Renders a tinted header (icon + label, with optional [labelTrailing]) and a
/// big value + unit. An optional [footer] holds extra context such as the
/// original weight and applied ratio.
class CalculatorFieldDisplay extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  /// Already-formatted value text; pass '0' for the empty state.
  final String value;
  final String unit;

  /// Dims [value] (e.g. while it is still the placeholder '0').
  final bool isPlaceholder;

  /// Optional widget shown to the right of [label], e.g. a '(per 100g)' note.
  final Widget? labelTrailing;

  /// Optional widget shown beneath the value row.
  final Widget? footer;

  const CalculatorFieldDisplay({
    Key? key,
    required this.icon,
    required this.label,
    required this.color,
    required this.value,
    required this.unit,
    this.isPlaceholder = false,
    this.labelTrailing,
    this.footer,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appColors = AppColors.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: ShapeDecoration(
        color: isDark ? Colors.grey[850] : Colors.grey[100],
        shape: AppCard.squircleBorder(
          radius: 12,
          side: BorderSide(
            color: color.withValues(alpha: 0.5),
            width: 2,
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              if (labelTrailing != null) ...[
                const SizedBox(width: 4),
                labelTrailing!,
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w500,
                  color: isPlaceholder
                      ? appColors.textDisabled
                      : (isDark ? Colors.white : Colors.black87),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                unit,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          if (footer != null) ...[
            const SizedBox(height: 4),
            footer!,
          ],
        ],
      ),
    );
  }
}
