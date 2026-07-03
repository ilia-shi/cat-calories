import 'package:cat_calories/common/theme/colors.dart';
import 'package:cat_calories/common/widgets/app_card.dart';
import 'package:flutter/material.dart';

/// Five tappable dots for a 1..5 rating. Tapping the current value clears it
/// back to null — every entered value must stay revocable.
class RatingDots extends StatelessWidget {
  final String label;
  final int? value;
  final ValueChanged<int?> onChanged;

  const RatingDots({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final appColors = AppColors.of(context);
    final primary = Theme.of(context).primaryColor;

    return Row(
      children: [
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: appColors.textSecondary,
            ),
          ),
        ),
        for (var dot = 1; dot <= 5; dot++)
          GestureDetector(
            onTap: () => onChanged(dot == value ? null : dot),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
              child: Icon(
                value != null && dot <= value!
                    ? Icons.circle
                    : Icons.circle_outlined,
                size: 20,
                color: value != null && dot <= value!
                    ? primary
                    : appColors.textDisabled,
              ),
            ),
          ),
        if (value != null) ...[
          const SizedBox(width: 4),
          Text(
            '$value/5',
            style: TextStyle(fontSize: 12, color: appColors.textTertiary),
          ),
        ],
      ],
    );
  }
}

/// One-tap cook-time chips (10/20/30/45/60+ min). Tapping the selected chip
/// clears the value.
class CookTimeChips extends StatelessWidget {
  static const List<int> options = [10, 20, 30, 45, 60];

  final int? minutes;
  final ValueChanged<int?> onChanged;

  const CookTimeChips({
    super.key,
    required this.minutes,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final appColors = AppColors.of(context);
    final primary = Theme.of(context).primaryColor;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final option in options)
          GestureDetector(
            onTap: () => onChanged(option == minutes ? null : option),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: ShapeDecoration(
                color: option == minutes
                    ? appColors.tintedSurface(primary, alpha: 0.18)
                    : appColors.surfaceMuted,
                shape: AppCard.squircleBorder(
                  radius: 10,
                  side: BorderSide(
                    color: option == minutes ? primary : appColors.border,
                  ),
                ),
              ),
              child: Text(
                option == 60 ? '60+ min' : '$option min',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: option == minutes
                      ? appColors.tintedText(primary)
                      : appColors.textSecondary,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
