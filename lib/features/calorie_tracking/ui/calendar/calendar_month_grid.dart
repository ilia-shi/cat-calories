import 'package:cat_calories/common/theme/colors.dart';
import 'package:cat_calories/common/widgets/app_card.dart';
import 'package:cat_calories/features/calorie_tracking/ui/calendar/calendar_bars.dart';
import 'package:cat_calories/features/calorie_tracking/ui/calendar/calendar_item.dart';
import 'package:cat_calories/features/calorie_tracking/ui/calendar/calendar_macro_lines.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Day items as one Monday-to-Sunday grid per month, newest month first.
class CalendarMonthGrids extends StatelessWidget {
  /// Newest first.
  final List<CalendarItem> items;

  const CalendarMonthGrids({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final months = <DateTime, List<CalendarItem>>{};
    for (final item in items) {
      final month = DateTime(item.start.year, item.start.month);
      months.putIfAbsent(month, () => []).add(item);
    }
    final keys = months.keys.toList();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      itemCount: keys.length,
      itemBuilder: (context, index) => _MonthGrid(
        month: keys[index],
        items: months[keys[index]]!,
      ),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  static const double _gap = 3;

  final DateTime month;
  final List<CalendarItem> items;

  const _MonthGrid({required this.month, required this.items});

  @override
  Widget build(BuildContext context) {
    final byDay = {for (final item in items) item.start.day: item};
    final dayCount = DateTime(month.year, month.month + 1, 0).day;
    final slots = <CalendarItem?>[
      ...List.filled(month.weekday - 1, null),
      for (var day = 1; day <= dayCount; day++) byDay[day],
    ];
    while (slots.length % 7 != 0) {
      slots.add(null);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            DateFormat('MMMM y').format(month),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.of(context).textPrimary,
            ),
          ),
        ),
        for (var start = 0; start < slots.length; start += 7)
          Padding(
            padding: const EdgeInsets.only(bottom: _gap),
            child: Row(
              children: [
                for (var i = start; i < start + 7; i++) ...[
                  if (i > start) const SizedBox(width: _gap),
                  Expanded(
                    child: slots[i] == null
                        ? const SizedBox.shrink()
                        : _GridCell(item: slots[i]!),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _GridCell extends StatelessWidget {
  static const double _height = 94;
  static const double _barsHeight = 20;
  static final _shape = AppCard.squircleBorder(radius: 6);

  final CalendarItem item;

  const _GridCell({required this.item});

  @override
  Widget build(BuildContext context) {
    final appColors = AppColors.of(context);
    final macros = item.macros;

    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1,
      child: SizedBox(
        height: _height,
        child: Material(
          color: appColors.surfaceMuted,
          shape: _shape,
          child: InkWell(
            customBorder: _shape,
            onTap: () => item.openDetails(context),
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${item.start.day}',
                    style: TextStyle(
                      fontSize: 9,
                      color: appColors.textSecondary,
                    ),
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      item.value,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: appColors.textPrimary,
                      ),
                    ),
                  ),
                  CalendarBars(
                    bars: item.bars,
                    showGoalLine: item.showGoalLine,
                    height: _barsHeight,
                  ),
                  if (macros != null)
                    CalendarMacroLines(
                      cell: macros,
                      showLetters: false,
                      fontSize: 9,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
