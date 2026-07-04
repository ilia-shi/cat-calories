import 'package:cat_calories/common/theme/colors.dart';
import 'package:cat_calories/common/widgets/app_card.dart';
import 'package:cat_calories/common/widgets/macro_chips.dart';
import 'package:cat_calories/features/calorie_tracking/ui/widgets/history/day_summary.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// A collapsible day group: a tappable header with the date, item/calorie
/// stats and macro totals, over an expandable list of that day's rows.
///
/// The day's rows are passed in pre-built as [dayItems] so record/meal tap
/// handling stays with the owning screen.
class DateGroupCard extends StatelessWidget {
  final DateTime date;
  final DaySummary summary;
  final bool isExpanded;
  final VoidCallback onToggle;
  final List<Widget> dayItems;

  const DateGroupCard({
    Key? key,
    required this.date,
    required this.summary,
    required this.isExpanded,
    required this.onToggle,
    required this.dayItems,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appColors = AppColors.of(context);
    final isToday = _isToday(date);
    final headerShape = AppCard.squircleBorder(bottom: !isExpanded);

    return AppCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: EdgeInsets.zero,
      emphasized: isToday,
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            customBorder: headerShape,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: ShapeDecoration(
                color: isToday
                    ? Theme.of(context).primaryColor.withValues(alpha: 0.05)
                    : null,
                shape: headerShape,
              ),
              child: _DateGroupHeader(
                date: date,
                summary: summary,
                isToday: isToday,
                isExpanded: isExpanded,
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              children: [
                Container(height: 1, color: appColors.border),
                ...dayItems,
              ],
            ),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}

class _DateGroupHeader extends StatelessWidget {
  final DateTime date;
  final DaySummary summary;
  final bool isToday;
  final bool isExpanded;

  const _DateGroupHeader({
    required this.date,
    required this.summary,
    required this.isToday,
    required this.isExpanded,
  });

  @override
  Widget build(BuildContext context) {
    final appColors = AppColors.of(context);
    return Column(
      children: [
        Row(
          children: [
            _DateBadge(date: date, isToday: isToday),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _dateLabel(date),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.w600,
                      color: appColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _StatChip(
                        value: '${summary.itemCount}',
                        label: 'items',
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      if (summary.positiveSum > 0)
                        _StatChip(
                          value: '+${summary.positiveSum.toStringAsFixed(0)}',
                          label: '',
                          color: DangerColor,
                        ),
                      if (summary.negativeSum < 0) ...[
                        const SizedBox(width: 4),
                        _StatChip(
                          value: summary.negativeSum.toStringAsFixed(0),
                          label: '',
                          color: SuccessColor,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            _DayTotal(summary: summary),
            const SizedBox(width: 8),
            AnimatedRotation(
              turns: isExpanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                Icons.keyboard_arrow_down,
                color: appColors.textDisabled,
              ),
            ),
          ],
        ),
        if (summary.hasMacroData) ...[
          const SizedBox(height: 10),
          _DayMacroSummary(summary: summary),
        ],
      ],
    );
  }
}

class _DateBadge extends StatelessWidget {
  final DateTime date;
  final bool isToday;

  const _DateBadge({required this.date, required this.isToday});

  @override
  Widget build(BuildContext context) {
    final appColors = AppColors.of(context);
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: isToday
            ? LinearGradient(
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withValues(alpha: 0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isToday ? null : appColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            DateFormat('d').format(date),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isToday ? Colors.white : appColors.textPrimary,
            ),
          ),
          Text(
            DateFormat('MMM').format(date).toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isToday
                  ? Colors.white.withValues(alpha: 0.9)
                  : appColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _DayTotal extends StatelessWidget {
  final DaySummary summary;

  const _DayTotal({required this.summary});

  @override
  Widget build(BuildContext context) {
    final appColors = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          summary.totalEaten.toStringAsFixed(0),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: summary.totalEaten > 2000
                ? DangerColor
                : summary.totalEaten > 1500
                    ? Colors.orange
                    : SuccessColor,
          ),
        ),
        Text(
          'kcal',
          style: TextStyle(fontSize: 12, color: appColors.textTertiary),
        ),
      ],
    );
  }
}

class _DayMacroSummary extends StatelessWidget {
  final DaySummary summary;

  const _DayMacroSummary({required this.summary});

  @override
  Widget build(BuildContext context) {
    final appColors = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: appColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: MacroBadgesRow(
          protein: summary.hasProteinData ? summary.totalProtein : null,
          fat: summary.hasFatData ? summary.totalFat : null,
          carbs: summary.hasCarbData ? summary.totalCarbs : null,
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _StatChip({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final appColors = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: appColors.tintedSurface(color),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$value${label.isNotEmpty ? ' $label' : ''}',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: appColors.tintedText(color),
        ),
      ),
    );
  }
}

String _dateLabel(DateTime date) {
  if (_isToday(date)) {
    return 'Today';
  }
  if (_isYesterday(date)) {
    return 'Yesterday';
  }
  return DateFormat('EEEE, MMM d, y').format(date);
}

bool _isToday(DateTime date) {
  final now = DateTime.now();
  return date.year == now.year &&
      date.month == now.month &&
      date.day == now.day;
}

bool _isYesterday(DateTime date) {
  final yesterday = DateTime.now().subtract(const Duration(days: 1));
  return date.year == yesterday.year &&
      date.month == yesterday.month &&
      date.day == yesterday.day;
}
