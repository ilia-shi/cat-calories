import 'package:cat_calories/app/state/calendar_content_cubit.dart';
import 'package:cat_calories/app/state/calendar_mode_cubit.dart';
import 'package:cat_calories/common/theme/colors.dart';
import 'package:cat_calories/common/widgets/app_card.dart';
import 'package:cat_calories/common/widgets/app_top_bar.dart';
import 'package:cat_calories/common/widgets/mode_button.dart';
import 'package:cat_calories/features/calorie_tracking/ui/calendar/calendar_bars.dart';
import 'package:cat_calories/features/calorie_tracking/ui/calendar/calendar_data_builder.dart';
import 'package:cat_calories/features/calorie_tracking/ui/calendar/calendar_item.dart';
import 'package:cat_calories/features/calorie_tracking/ui/calendar/calendar_labels.dart';
import 'package:cat_calories/features/calorie_tracking/ui/calendar/calendar_macro_lines.dart';
import 'package:cat_calories/features/calorie_tracking/ui/calendar/calendar_month_grid.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/calendar_cells.dart';
import 'package:cat_calories_core/features/metrics/domain/day_metric.dart';
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
    final mode = context.watch<CalendarModeCubit>().state;
    final metric = context.watch<CalendarContentCubit>().state;
    final items = calendarItems(data, mode, metric).reversed.toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
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
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Row(
            children: [
              for (final option in const [null, ...DayMetric.values])
                Expanded(
                  child: ModeButton(
                    label: calendarContentLabel(option),
                    icon: _contentIcon(option),
                    isSelected: option == metric,
                    onTap: () =>
                        context.read<CalendarContentCubit>().select(option),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? Center(
                  child: Text(metric == null ? 'No records yet' : 'No values yet'),
                )
              : mode == CalendarMode.days
                  ? CalendarMonthGrids(items: items)
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 6),
                      itemBuilder: (context, index) =>
                          _PeriodRow(item: items[index]),
                    ),
        ),
      ],
    );
  }
}

IconData _contentIcon(DayMetric? metric) {
  return switch (metric) {
    null => Icons.restaurant_outlined,
    DayMetric.steps => Icons.directions_walk,
    DayMetric.sleepMinutes => Icons.bedtime_outlined,
    DayMetric.burnedKcal => Icons.local_fire_department_outlined,
  };
}

class _PeriodRow extends StatelessWidget {
  static const double _barsHeight = 44;
  static final _shape = AppCard.squircleBorder(radius: 10);

  final CalendarItem item;

  const _PeriodRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final appColors = AppColors.of(context);
    final macros = item.macros;

    return Material(
      color: appColors.surfaceMuted,
      shape: _shape,
      child: InkWell(
        customBorder: _shape,
        onTap: () => item.openDetails(context),
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
                      shortPeriodLabel(item.start, item.mode),
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 12,
                        color: appColors.textSecondary,
                      ),
                    ),
                    Text(
                      item.value,
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
                  bars: item.bars,
                  showGoalLine: item.showGoalLine,
                  height: _barsHeight,
                ),
              ),
              if (macros != null) ...[
                const SizedBox(width: 12),
                SizedBox(width: 52, child: CalendarMacroLines(cell: macros)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
