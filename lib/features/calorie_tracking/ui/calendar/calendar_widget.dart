import 'package:cat_calories/app/state/calendar_content_cubit.dart';
import 'package:cat_calories/app/state/calendar_mode_cubit.dart';
import 'package:cat_calories/common/theme/colors.dart';
import 'package:cat_calories/common/widgets/app_card.dart';
import 'package:cat_calories/common/widgets/horizontal_drag_scroll_area.dart';
import 'package:cat_calories/features/calorie_tracking/ui/calendar/calendar_cell_card.dart';
import 'package:cat_calories/features/calorie_tracking/ui/calendar/calendar_data_builder.dart';
import 'package:cat_calories/features/calorie_tracking/ui/calendar/calendar_item.dart';
import 'package:cat_calories/features/calorie_tracking/ui/calendar/calendar_labels.dart';
import 'package:cat_calories/features/calorie_tracking/ui/calendar/calendar_screen.dart';
import 'package:cat_calories/features/calorie_tracking/ui/tracking_gap_form_screen.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/calendar_cells.dart';
import 'package:cat_calories_core/features/metrics/domain/day_metric.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CalendarWidget extends StatelessWidget {
  const CalendarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return CalendarDataBuilder(
      builder: (context, data) => CalendarStrip(data: data),
    );
  }
}

enum _MenuAction { food, openFullScreen, addGap }

class CalendarStrip extends StatelessWidget {
  static const double _cellGap = 6;

  final CalendarData data;

  const CalendarStrip({super.key, required this.data});

  void _onMenu(BuildContext context, Object choice) {
    switch (choice) {
      case CalendarMode mode:
        context.read<CalendarModeCubit>().select(mode);
      case DayMetric metric:
        context.read<CalendarContentCubit>().select(metric);
      case _MenuAction.food:
        context.read<CalendarContentCubit>().select(null);
      case _MenuAction.openFullScreen:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CalendarScreen()),
        );
      case _MenuAction.addGap:
        TrackingGapFormScreen.openNew(context, data.profileId);
    }
  }

  List<PopupMenuEntry<Object>> _menuItems(
      CalendarMode mode, DayMetric? metric) {
    return [
      for (final option in CalendarMode.values)
        CheckedPopupMenuItem<Object>(
          value: option,
          checked: option == mode,
          child: Text(calendarModeLabel(option)),
        ),
      const PopupMenuDivider(),
      CheckedPopupMenuItem<Object>(
        value: _MenuAction.food,
        checked: metric == null,
        child: Text(calendarContentLabel(null)),
      ),
      for (final option in DayMetric.values)
        CheckedPopupMenuItem<Object>(
          value: option,
          checked: option == metric,
          child: Text(calendarContentLabel(option)),
        ),
      const PopupMenuDivider(),
      const PopupMenuItem<Object>(
        value: _MenuAction.openFullScreen,
        child: Text('Open full screen'),
      ),
      const PopupMenuItem<Object>(
        value: _MenuAction.addGap,
        child: Text('Add gap'),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final appColors = AppColors.of(context);

    final mode = context.watch<CalendarModeCubit>().state;
    final metric = context.watch<CalendarContentCubit>().state;
    final items = calendarItems(data, mode, metric);

    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${metric?.title ?? 'Calendar'} · ${calendarModeLabel(mode)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: appColors.textPrimary,
                  ),
                ),
              ),
              PopupMenuButton<Object>(
                icon: const Icon(Icons.more_vert, size: 18),
                tooltip: 'Calendar options',
                padding: EdgeInsets.zero,
                onSelected: (choice) => _onMenu(context, choice),
                itemBuilder: (_) => _menuItems(mode, metric),
              ),
            ],
          ),
          if (items.isEmpty)
            Text(
              metric == null ? 'No records yet' : 'No values yet',
              style: TextStyle(fontSize: 13, color: appColors.textSecondary),
            )
          else
            // Cells have a fixed height, so large system text would overflow.
            MediaQuery.withClampedTextScaling(
              maxScaleFactor: 1,
              child: SizedBox(
                height: CalendarCellCard.height,
                child: ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context)
                      .copyWith(dragDevices: allDragDevices),
                  child: ListView.separated(
                    key: ValueKey((mode, metric)),
                    scrollDirection: Axis.horizontal,
                    reverse: true,
                    itemCount: items.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(width: _cellGap),
                    itemBuilder: (context, index) => SizedBox(
                      width: CalendarCellCard.widthFor(mode),
                      child: CalendarCellCard(
                        item: items[items.length - 1 - index],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
