import 'package:cat_calories/common/theme/colors.dart';
import 'package:cat_calories/common/widgets/app_card.dart';
import 'package:cat_calories/features/calorie_tracking/ui/calendar/calendar_data_builder.dart';
import 'package:cat_calories/features/calorie_tracking/ui/calendar/calendar_labels.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/calendar_cells.dart';
import 'package:cat_calories_core/features/metrics/domain/metric_cells.dart';
import 'package:flutter/material.dart';

class CalendarMetricSheet extends StatelessWidget {
  final MetricCell cell;
  final CalendarData data;

  const CalendarMetricSheet({
    super.key,
    required this.cell,
    required this.data,
  });

  static Future<void> show(
    BuildContext context,
    MetricCell cell,
    CalendarData data,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: AppCard.squircleBorder(radius: 20, bottom: false),
      builder: (_) => CalendarMetricSheet(cell: cell, data: data),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appColors = AppColors.of(context);

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
            if (data.hasMetricValues(cell.start, cell.mode))
              CalendarMetricRows(
                start: cell.start,
                mode: cell.mode,
                data: data,
              )
            else
              Text(
                'No values in this period',
                style: TextStyle(fontSize: 14, color: appColors.textSecondary),
              ),
          ],
        ),
      ),
    );
  }
}

/// One row per metric that has a value in the period.
class CalendarMetricRows extends StatelessWidget {
  final DateTime start;
  final CalendarMode mode;
  final CalendarData data;

  const CalendarMetricRows({
    super.key,
    required this.start,
    required this.mode,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final cells = data.metricsOfPeriod(start, mode);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final cell in cells)
          CalendarDetailRow(
            cell.metric.title,
            cell.detailLabel,
            note: mode == CalendarMode.days ? cell.days.single.note : null,
          ),
      ],
    );
  }
}

class CalendarDetailRow extends StatelessWidget {
  final String label;
  final String value;
  final String? note;

  const CalendarDetailRow(this.label, this.value, {super.key, this.note});

  @override
  Widget build(BuildContext context) {
    final appColors = AppColors.of(context);
    final note = this.note;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 14, color: appColors.textSecondary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: appColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          if (note != null)
            Text(
              note,
              style: TextStyle(fontSize: 13, color: appColors.textSecondary),
            ),
        ],
      ),
    );
  }
}
