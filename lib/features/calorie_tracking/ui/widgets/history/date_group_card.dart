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

  /// Plans a meal straight onto this day. Offered on today and the days ahead
  /// only — "plan" is not something one does to a day already gone, and a
  /// forgotten meal is logged through the toolbar's own entry instead.
  final VoidCallback? onPlanMeal;

  const DateGroupCard({
    Key? key,
    required this.date,
    required this.summary,
    required this.isExpanded,
    required this.onToggle,
    required this.dayItems,
    this.onPlanMeal,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appColors = AppColors.of(context);
    final isToday = _isToday(date);
    final isUpcoming = _isUpcoming(date);
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
                isUpcoming: isUpcoming,
                isExpanded: isExpanded,
                onPlanMeal:
                    isToday || isUpcoming ? onPlanMeal : null,
              ),
            ),
          ),
          // Conditional child (not a cross-fade of both) so a collapsed day
          // builds none of its rows; AnimatedSize keeps the expand smooth.
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: isExpanded
                ? Column(
                    children: [
                      Container(height: 1, color: appColors.border),
                      ...dayItems,
                    ],
                  )
                : const SizedBox(width: double.infinity),
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
  final bool isUpcoming;
  final bool isExpanded;
  final VoidCallback? onPlanMeal;

  const _DateGroupHeader({
    required this.date,
    required this.summary,
    required this.isToday,
    required this.isUpcoming,
    required this.isExpanded,
    required this.onPlanMeal,
  });

  @override
  Widget build(BuildContext context) {
    final appColors = AppColors.of(context);
    return Column(
      children: [
        Row(
          children: [
            _DateBadge(date: date, isToday: isToday, isUpcoming: isUpcoming),
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
                      // Only on a day that has both: when nothing is eaten yet
                      // the planned figure is already the day's headline.
                      if (summary.plannedKcal > 0 &&
                          !summary.showsPlannedTotal) ...[
                        _StatChip(
                          value: summary.plannedKcal.toStringAsFixed(0),
                          label: 'planned',
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 8),
                      ],
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
            if (onPlanMeal != null)
              IconButton(
                onPressed: onPlanMeal,
                icon: const Icon(Icons.post_add, size: 20),
                color: Theme.of(context).primaryColor,
                visualDensity: VisualDensity.compact,
                tooltip: 'Plan a meal for this day',
              )
            else
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

/// The day-and-month tile. Today is filled with the accent gradient, a day
/// still to come is only outlined in it — the same colour says "this is the
/// one that matters", the fill says whether it has happened.
class _DateBadge extends StatelessWidget {
  static final _dayFormat = DateFormat('d');
  static final _monthFormat = DateFormat('MMM');

  final DateTime date;
  final bool isToday;
  final bool isUpcoming;

  const _DateBadge({
    required this.date,
    required this.isToday,
    required this.isUpcoming,
  });

  @override
  Widget build(BuildContext context) {
    final appColors = AppColors.of(context);
    final accent = Theme.of(context).primaryColor;
    final foreground = isToday
        ? Colors.white
        : isUpcoming
            ? accent
            : appColors.textPrimary;

    return Container(
      width: 56,
      height: 56,
      decoration: ShapeDecoration(
        gradient: isToday
            ? LinearGradient(
                colors: [accent, accent.withValues(alpha: 0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isToday
            ? null
            : isUpcoming
                ? Colors.transparent
                : appColors.surfaceSubtle,
        shape: AppCard.squircleBorder(
          radius: 12,
          side: isUpcoming
              ? BorderSide(color: accent.withValues(alpha: 0.5))
              : BorderSide.none,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _dayFormat.format(date),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: foreground,
            ),
          ),
          Text(
            _monthFormat.format(date).toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isToday
                  ? Colors.white.withValues(alpha: 0.9)
                  : isUpcoming
                      ? accent
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
    // A day with nothing eaten yet leads with what is planned instead of a
    // green zero, which would read as "kept under the limit" for a day that
    // has not happened.
    final showsPlanned = summary.showsPlannedTotal;
    final value = showsPlanned ? summary.plannedKcal : summary.totalEaten;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          value.toStringAsFixed(0),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: showsPlanned
                ? appColors.textSecondary
                : summary.totalEaten > 2000
                    ? DangerColor
                    : summary.totalEaten > 1500
                        ? Colors.orange
                        : SuccessColor,
          ),
        ),
        Text(
          showsPlanned ? 'kcal planned' : 'kcal',
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
      decoration: ShapeDecoration(
        color: appColors.tintedSurface(color),
        shape: AppCard.squircleBorder(radius: 8),
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

final _fullDateFormat = DateFormat('EEEE, MMM d, y');

String _dateLabel(DateTime date) {
  if (_isToday(date)) {
    return 'Today';
  }
  if (_isDayFromToday(date, -1)) {
    return 'Yesterday';
  }
  if (_isDayFromToday(date, 1)) {
    return 'Tomorrow';
  }
  return _fullDateFormat.format(date);
}

bool _isToday(DateTime date) => _isDayFromToday(date, 0);

/// True for a day the user has not reached yet, which renders as planned
/// rather than recorded.
bool _isUpcoming(DateTime date) {
  final now = DateTime.now();
  return date.isAfter(DateTime(now.year, now.month, now.day));
}

/// Built by field rather than `add(Duration(days:))`, which lands an hour off
/// across a daylight-saving change and would mislabel the neighbouring day.
bool _isDayFromToday(DateTime date, int offset) {
  final now = DateTime.now();
  final target = DateTime(now.year, now.month, now.day + offset);
  return date.year == target.year &&
      date.month == target.month &&
      date.day == target.day;
}
