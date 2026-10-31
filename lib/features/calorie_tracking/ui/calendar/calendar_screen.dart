import 'package:cat_calories/app/state/calendar_mode_cubit.dart';
import 'package:cat_calories/common/theme/colors.dart';
import 'package:cat_calories/common/widgets/app_card.dart';
import 'package:cat_calories/common/widgets/app_top_bar.dart';
import 'package:cat_calories/common/widgets/mode_button.dart';
import 'package:cat_calories/features/calorie_tracking/ui/calendar/calendar_bars.dart';
import 'package:cat_calories/features/calorie_tracking/ui/calendar/calendar_cell_sheet.dart';
import 'package:cat_calories/features/calorie_tracking/ui/calendar/calendar_data_builder.dart';
import 'package:cat_calories/features/calorie_tracking/ui/calendar/calendar_labels.dart';
import 'package:cat_calories/features/calorie_tracking/ui/calendar/calendar_macro_lines.dart';
import 'package:cat_calories/features/calorie_tracking/ui/calendar/calendar_month_grid.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/calendar_cells.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(title: 'Calendar'),
      body: CalendarDataBuilder(
        builder: (context, data) => CalendarScreenBody(data: data),
      ),
    );
  }
}

class CalendarScreenBody extends StatelessWidget {
  final CalendarData data;

  const CalendarScreenBody({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CalendarModeCubit, CalendarMode>(
      builder: (context, mode) {
        final cells = data.cells(mode).reversed.toList();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  for (final option in CalendarMode.values)
                    Expanded(
                      child: ModeButton(
                        label: calendarModeLabel(option),
                        icon: Icons.calendar_today_outlined,
                        isSelected: option == mode,
                        onTap: () =>
                            context.read<CalendarModeCubit>().select(option),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: mode == CalendarMode.days
                  ? CalendarMonthGrids(cells: cells, data: data)
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      itemCount: cells.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 6),
                      itemBuilder: (context, index) =>
                          _PeriodRow(cell: cells[index], data: data),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _PeriodRow extends StatelessWidget {
  static const double _barsHeight = 44;
  static final _shape = AppCard.squircleBorder(radius: 10);

  final CalendarCell cell;
  final CalendarData data;

  const _PeriodRow({required this.cell, required this.data});

  @override
  Widget build(BuildContext context) {
    final appColors = AppColors.of(context);

    return Material(
      color: appColors.surfaceMuted,
      shape: _shape,
      child: InkWell(
        customBorder: _shape,
        onTap: () => CalendarCellSheet.show(context, cell, data),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              SizedBox(
                width: 76,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shortPeriodLabel(cell),
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 12,
                        color: appColors.textSecondary,
                      ),
                    ),
                    Text(
                      cell.kcalLabel,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: appColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CalendarBars(
                  days: cell.days,
                  goal: data.goal,
                  height: _barsHeight,
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(width: 52, child: CalendarMacroLines(cell: cell)),
            ],
          ),
        ),
      ),
    );
  }
}
