import 'package:cat_calories/common/theme/colors.dart';
import 'package:cat_calories/common/widgets/app_card.dart';
import 'package:flutter/material.dart';

/// One tappable option in a row of choices: muted while unselected, tinted with
/// the primary colour once selected.
class SelectableChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  const SelectableChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final appColors = AppColors.of(context);
    final primary = Theme.of(context).primaryColor;
    final foreground =
        selected ? appColors.tintedText(primary) : appColors.textSecondary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: ShapeDecoration(
          color: selected
              ? appColors.tintedSurface(primary, alpha: 0.18)
              : appColors.surfaceMuted,
          shape: AppCard.squircleBorder(
            radius: 10,
            side: BorderSide(color: selected ? primary : appColors.border),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 13, color: foreground),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: foreground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
