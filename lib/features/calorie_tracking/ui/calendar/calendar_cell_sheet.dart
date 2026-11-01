import 'package:cat_calories/common/theme/colors.dart';
import 'package:cat_calories/common/widgets/app_card.dart';
import 'package:cat_calories/features/calorie_tracking/ui/calendar/calendar_data_builder.dart';
import 'package:cat_calories/features/calorie_tracking/ui/calendar/calendar_labels.dart';
import 'package:cat_calories/features/calorie_tracking/ui/calendar/calendar_metric_sheet.dart';
import 'package:cat_calories/features/calorie_tracking/ui/day_calories_page.dart';
import 'package:cat_calories/features/calorie_tracking/ui/tracking_gap_form_screen.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/calendar_cells.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/tracking_gap.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CalendarCellSheet extends StatelessWidget {
  static final _gapFormat = DateFormat('MMM d, HH:mm');

  final CalendarCell cell;
  final CalendarData data;
  final BuildContext hostContext;

  const CalendarCellSheet({
    super.key,
    required this.cell,
    required this.data,
    required this.hostContext,
  });

  static Future<void> show(
    BuildContext context,
    CalendarCell cell,
    CalendarData data,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: AppCard.squircleBorder(radius: 20, bottom: false),
      builder: (_) => CalendarCellSheet(
        cell: cell,
        data: data,
        hostContext: context,
      ),
    );
  }

  void _addGap(BuildContext context) {
    final (start, end) = cell.gapBounds(DateTime.now());

    Navigator.of(context).pop();
    TrackingGapFormScreen.open(
      hostContext,
      profileId: data.profileId,
      start: start,
      end: end,
    );
  }

  void _editGap(BuildContext context, TrackingGap gap) {
    Navigator.of(context).pop();
    TrackingGapFormScreen.open(
      hostContext,
      gap: gap,
      profileId: data.profileId,
      start: gap.startedAt,
      end: gap.endedAt,
    );
  }

  void _showRecords(BuildContext context) {
    Navigator.of(context).pop();
    Navigator.of(hostContext).push(MaterialPageRoute(
      builder: (_) => DayCaloriesPage(cell.start),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final appColors = AppColors.of(context);
    final average = cell.averageKcal;
    final gaps = data.gaps
        .where((gap) => !gap.isDeleted && gap.overlaps(cell.start, cell.end));

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              fullPeriodLabel(cell.start, cell.end, cell.mode),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: appColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            CalendarDetailRow('Calories', '${cell.kcalLabel} kcal'),
            if (cell.mode != CalendarMode.days && average != null)
              CalendarDetailRow(
                'Average',
                '${average.round()} per day, '
                    '${cell.countedDays} of ${cell.days.length} days',
              ),
            CalendarDetailRow('Protein', '${cell.macroLabel(cell.protein)} g'),
            CalendarDetailRow('Fat', '${cell.macroLabel(cell.fat)} g'),
            CalendarDetailRow('Carbs', '${cell.macroLabel(cell.carbs)} g'),
            CalendarDetailRow(
              'With macros',
              '${cell.recordsWithMacros} of ${cell.recordCount} records',
            ),
            CalendarMetricRows(start: cell.start, mode: cell.mode, data: data),
            for (final gap in gaps)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event_busy_outlined),
                title: Text(
                  '${_gapFormat.format(gap.startedAt)} - '
                  '${_gapFormat.format(gap.endedAt)}',
                ),
                subtitle:
                    gap.description == null ? null : Text(gap.description!),
                onTap: () => _editGap(context, gap),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                TextButton(
                  onPressed: () => _addGap(context),
                  child: const Text('Add gap'),
                ),
                if (cell.mode == CalendarMode.days)
                  TextButton(
                    onPressed: () => _showRecords(context),
                    child: const Text('Show records'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
