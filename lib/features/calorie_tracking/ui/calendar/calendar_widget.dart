import 'package:cat_calories/app/state/calendar_mode_cubit.dart';
import 'package:cat_calories/common/theme/colors.dart';
import 'package:cat_calories/common/widgets/app_card.dart';
import 'package:cat_calories/common/widgets/horizontal_drag_scroll_area.dart';
import 'package:cat_calories/features/calorie_tracking/ui/calendar/calendar_cell_card.dart';
import 'package:cat_calories/features/calorie_tracking/ui/calendar/calendar_cell_sheet.dart';
import 'package:cat_calories/features/calorie_tracking/ui/calendar/calendar_data_builder.dart';
import 'package:cat_calories/features/calorie_tracking/ui/calendar/calendar_labels.dart';
import 'package:cat_calories/features/calorie_tracking/ui/calendar/calendar_screen.dart';
import 'package:cat_calories/features/calorie_tracking/ui/tracking_gap_form_screen.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/calendar_cells.dart';
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

enum _MenuAction { days, weeks, months, openFullScreen, addGap }

class CalendarStrip extends StatelessWidget {
  static const double _cellGap = 6;

  final CalendarData data;

  const CalendarStrip({super.key, required this.data});

  void _onMenu(BuildContext context, _MenuAction action) {
    final cubit = context.read<CalendarModeCubit>();

    switch (action) {
      case _MenuAction.days:
        cubit.select(CalendarMode.days);
      case _MenuAction.weeks:
        cubit.select(CalendarMode.weeks);
      case _MenuAction.months:
        cubit.select(CalendarMode.months);
      case _MenuAction.openFullScreen:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CalendarScreen()),
        );
      case _MenuAction.addGap:
        TrackingGapFormScreen.openNew(context, data.profileId);
    }
  }

  CheckedPopupMenuItem<_MenuAction> _modeItem(
    _MenuAction action,
    CalendarMode mode,
    CalendarMode current,
  ) {
    return CheckedPopupMenuItem(
      value: action,
      checked: mode == current,
      child: Text(calendarModeLabel(mode)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appColors = AppColors.of(context);

    return BlocBuilder<CalendarModeCubit, CalendarMode>(
      builder: (context, mode) {
        final cells = data.cells(mode);

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
                      'Calendar · ${calendarModeLabel(mode)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: appColors.textPrimary,
                      ),
                    ),
                  ),
                  PopupMenuButton<_MenuAction>(
                    icon: const Icon(Icons.more_vert, size: 18),
                    tooltip: 'Calendar options',
                    padding: EdgeInsets.zero,
                    onSelected: (action) => _onMenu(context, action),
                    itemBuilder: (_) => [
                      _modeItem(_MenuAction.days, CalendarMode.days, mode),
                      _modeItem(_MenuAction.weeks, CalendarMode.weeks, mode),
                      _modeItem(_MenuAction.months, CalendarMode.months, mode),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: _MenuAction.openFullScreen,
                        child: Text('Open full screen'),
                      ),
                      const PopupMenuItem(
                        value: _MenuAction.addGap,
                        child: Text('Add gap'),
                      ),
                    ],
                  ),
                ],
              ),
              if (cells.isEmpty)
                Text(
                  'No records yet',
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
                        key: ValueKey(mode),
                        scrollDirection: Axis.horizontal,
                        reverse: true,
                        itemCount: cells.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(width: _cellGap),
                        itemBuilder: (context, index) {
                          final cell = cells[cells.length - 1 - index];

                          return SizedBox(
                            width: CalendarCellCard.widthFor(mode),
                            child: CalendarCellCard(
                              cell: cell,
                              goal: data.goal,
                              onTap: () =>
                                  CalendarCellSheet.show(context, cell, data),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
