import 'package:cat_calories/common/theme/colors.dart';
import 'package:cat_calories/common/widgets/macro_chips.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/calorie_record.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// A single calorie record row inside an expanded day group.
class CalorieRecordRow extends StatelessWidget {
  final CalorieRecord item;
  final bool isSelected;
  final bool isLast;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const CalorieRecordRow({
    Key? key,
    required this.item,
    required this.isSelected,
    required this.isLast,
    required this.onTap,
    required this.onLongPress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appColors = AppColors.of(context);
    final hasMacros = item.proteinGrams != null ||
        item.fatGrams != null ||
        item.carbGrams != null;

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor.withValues(alpha: 0.08)
              : null,
          border: isLast
              ? null
              : Border(
                  bottom: BorderSide(
                    color: appColors.borderSubtle,
                  ),
                ),
        ),
        child: Opacity(
          opacity: item.isEaten() ? 1.0 : 0.5,
          child: Column(
            children: [
              Row(
                children: [
                  _TimeColumn(item: item),
                  const SizedBox(width: 12),
                  // Color indicator
                  Container(
                    width: 4,
                    height: 44,
                    decoration: BoxDecoration(
                      color: item.value > 0 ? DangerLiteColor : SuccessColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Description
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (item.description != null &&
                            item.description!.isNotEmpty)
                          Text(
                            item.description!,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          )
                        else
                          Text(
                            'No description',
                            style: TextStyle(
                              fontSize: 14,
                              color: appColors.textDisabled,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Calories value
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: (item.value > 0 ? DangerColor : SuccessColor)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${item.value >= 0 ? '+' : ''}${item.value.toStringAsFixed(0)} kcal',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: item.value > 0 ? DangerColor : SuccessColor,
                      ),
                    ),
                  ),
                ],
              ),
              if (hasMacros && item.isEaten()) ...[
                const SizedBox(height: 8),
                CalorieRecordMacros(item: item),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TimeColumn extends StatelessWidget {
  final CalorieRecord item;

  const _TimeColumn({required this.item});

  @override
  Widget build(BuildContext context) {
    final appColors = AppColors.of(context);
    return Container(
      width: 56,
      alignment: Alignment.center,
      child: Column(
        children: [
          Text(
            DateFormat('HH:mm').format(item.createdAt),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: appColors.textSecondary,
            ),
          ),
          if (item.isEaten())
            _StatusBadge(
              label: 'Eaten',
              background: SuccessColor.withValues(alpha: 0.1),
              textColor: SuccessColor,
            )
          else
            _StatusBadge(
              label: 'Planned',
              background: appColors.border,
              textColor: appColors.textSecondary,
            ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color background;
  final Color textColor;

  const _StatusBadge({
    required this.label,
    required this.background,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Compact macro + weight strip shown under a record. Reused by the record
/// options bottom sheet, so it is public.
class CalorieRecordMacros extends StatelessWidget {
  final CalorieRecord item;

  const CalorieRecordMacros({Key? key, required this.item}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appColors = AppColors.of(context);
    return Container(
      margin: const EdgeInsets.only(left: 80),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: appColors.surfaceMuted,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: appColors.border),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          MacroBadgesRow(
            protein: item.proteinGrams,
            fat: item.fatGrams,
            carbs: item.carbGrams,
          ),
          if (item.weightGrams != null)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 12,
                  width: 1,
                  color: appColors.border,
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.scale,
                  size: 12,
                  color: appColors.textTertiary,
                ),
                const SizedBox(width: 4),
                Text(
                  '${item.weightGrams!.round()}g',
                  style: TextStyle(
                    fontSize: 11,
                    color: appColors.textSecondary,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
