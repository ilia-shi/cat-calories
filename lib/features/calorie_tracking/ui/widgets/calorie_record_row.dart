import 'package:cat_calories/common/theme/colors.dart';
import 'package:cat_calories/common/widgets/color_label_dot.dart';
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

  /// Null where rows aren't selectable, e.g. a meal's ingredient list.
  final VoidCallback? onLongPress;

  /// Keeps the macro/weight strip visible on planned rows and on rows carrying
  /// only a weight. The history list hides it there to stay scannable; cooking
  /// mode is the opposite case — the weights matter most while the dish is
  /// still being assembled.
  final bool showDetails;

  const CalorieRecordRow({
    Key? key,
    required this.item,
    required this.isSelected,
    required this.isLast,
    required this.onTap,
    this.onLongPress,
    this.showDetails = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appColors = AppColors.of(context);
    final hasMacros = item.proteinGrams != null ||
        item.fatGrams != null ||
        item.carbGrams != null;
    final showStrip = showDetails
        ? hasMacros || item.weightGrams != null || item.costValue != null
        : hasMacros && item.isEaten();

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor.withValues(alpha: 0.25)
              : null,
          border: isLast
              ? null
              : Border(
                  bottom: BorderSide(
                    color: appColors.borderSubtle,
                  ),
                ),
        ),
        child: _DimmedIfPlanned(
          isEaten: item.isEaten(),
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
                  // Color label + description
                  Expanded(child: _DescriptionCell(item: item)),
                  const SizedBox(width: 8),
                  // Calories value
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
              if (showStrip) ...[
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

class _DescriptionCell extends StatelessWidget {
  final CalorieRecord item;

  const _DescriptionCell({required this.item});

  @override
  Widget build(BuildContext context) {
    final appColors = AppColors.of(context);
    final colorLabel = item.colorLabel;
    final description = item.description;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (colorLabel != null) ...[
          // Nudged down so the dot sits on the first line when text wraps.
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: ColorLabelDot(color: colorLabel),
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: description != null && description.isNotEmpty
              ? Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                )
              : Text(
                  'No description',
                  style: TextStyle(
                    fontSize: 14,
                    color: appColors.textDisabled,
                    fontStyle: FontStyle.italic,
                  ),
                ),
        ),
      ],
    );
  }
}

/// Dims planned (not-yet-eaten) rows. [Opacity] forces a `saveLayer`, so it is
/// skipped entirely for eaten rows (the common case) — only planned rows pay.
class _DimmedIfPlanned extends StatelessWidget {
  final bool isEaten;
  final Widget child;

  const _DimmedIfPlanned({required this.isEaten, required this.child});

  @override
  Widget build(BuildContext context) {
    if (isEaten) {
      return child;
    }
    return Opacity(opacity: 0.5, child: child);
  }
}

class _TimeColumn extends StatelessWidget {
  static final _timeFormat = DateFormat('HH:mm');

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
            _timeFormat.format(item.createdAt),
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

/// Compact macro + weight + cost strip shown under a record. Reused by the
/// record options bottom sheet, so it is public.
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
            _StripFact(
              icon: Icons.scale,
              label: '${item.weightGrams!.round()}g',
            ),
          if (item.costValue != null)
            _StripFact(
              icon: Icons.payments_outlined,
              label: '${item.costValue!.toStringAsFixed(2)} '
                      '${item.costCurrency ?? ''}'
                  .trim(),
            ),
        ],
      ),
    );
  }
}

/// One divider-separated fact (weight, cost) trailing the macro badges.
class _StripFact extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StripFact({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final appColors = AppColors.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 12,
          width: 1,
          color: appColors.border,
        ),
        const SizedBox(width: 12),
        Icon(icon, size: 12, color: appColors.textTertiary),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: appColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
