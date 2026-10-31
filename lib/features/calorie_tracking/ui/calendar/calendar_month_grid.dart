import 'package:cat_calories/common/theme/colors.dart';
import 'package:cat_calories/common/widgets/app_card.dart';
import 'package:cat_calories/features/calorie_tracking/ui/calendar/calendar_bars.dart';
import 'package:cat_calories/features/calorie_tracking/ui/calendar/calendar_cell_sheet.dart';
import 'package:cat_calories/features/calorie_tracking/ui/calendar/calendar_data_builder.dart';
import 'package:cat_calories/features/calorie_tracking/ui/calendar/calendar_macro_lines.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/calendar_cells.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Day cells as one Monday-to-Sunday grid per month, newest month first.
class CalendarMonthGrids extends StatelessWidget {
  /// Newest first.
  final List<CalendarCell> cells;
  final CalendarData data;

  const CalendarMonthGrids({
    super.key,
    required this.cells,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final months = <DateTime, List<CalendarCell>>{};
    for (final cell in cells) {
      final month = DateTime(cell.start.year, cell.start.month);
      months.putIfAbsent(month, () => []).add(cell);
    }
    final keys = months.keys.toList();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      itemCount: keys.length,
      itemBuilder: (context, index) => _MonthGrid(
        month: keys[index],
        cells: months[keys[index]]!,
        data: data,
      ),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  static const double _gap = 3;

  final DateTime month;
  final List<CalendarCell> cells;
  final CalendarData data;

  const _MonthGrid({
    required this.month,
    required this.cells,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final byDay = {for (final cell in cells) cell.start.day: cell};
    final dayCount = DateTime(month.year, month.month + 1, 0).day;
    final slots = <CalendarCell?>[
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
                        : _GridCell(cell: slots[i]!, data: data),
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

  final CalendarCell cell;
  final CalendarData data;

  const _GridCell({required this.cell, required this.data});

  @override
  Widget build(BuildContext context) {
    final appColors = AppColors.of(context);

    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1,
      child: SizedBox(
        height: _height,
        child: Material(
          color: appColors.surfaceMuted,
          shape: _shape,
          child: InkWell(
            customBorder: _shape,
            onTap: () => CalendarCellSheet.show(context, cell, data),
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${cell.start.day}',
                    style: TextStyle(
                      fontSize: 9,
                      color: appColors.textSecondary,
                    ),
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      cell.kcalLabel,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: appColors.textPrimary,
                      ),
                    ),
                  ),
                  CalendarBars(
                    days: cell.days,
                    goal: data.goal,
                    height: _barsHeight,
                  ),
                  CalendarMacroLines(
                    cell: cell,
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
