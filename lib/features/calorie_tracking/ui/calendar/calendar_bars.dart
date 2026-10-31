import 'package:cat_calories/common/theme/colors.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/calendar_cells.dart';
import 'package:flutter/material.dart';

/// One bar per day of a period, with the goal line at half height.
class CalendarBars extends StatelessWidget {
  final List<CalendarDay> days;
  final double goal;
  final double height;

  const CalendarBars({
    super.key,
    required this.days,
    required this.goal,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final appColors = AppColors.of(context);
    final primary = Theme.of(context).colorScheme.primary;

    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: CalendarBarsPainter(
          days: days,
          goal: goal,
          normal: primary,
          today: primary.withValues(alpha: 0.45),
          muted: appColors.textDisabled,
          over: Theme.of(context).colorScheme.error,
          slot: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.2),
          line: appColors.textSecondary,
        ),
      ),
    );
  }
}

class CalendarBarsPainter extends CustomPainter {
  static const double _dotRadius = 1.5;

  final List<CalendarDay> days;
  final double goal;
  final Color normal;
  final Color today;
  final Color muted;
  final Color over;
  final Color slot;
  final Color line;

  const CalendarBarsPainter({
    required this.days,
    required this.goal,
    required this.normal,
    required this.today,
    required this.muted,
    required this.over,
    required this.slot,
    required this.line,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final gap = days.length > 7 ? 1.0 : 2.0;
    final width = (size.width - gap * (days.length - 1)) / days.length;

    for (var i = 0; i < days.length; i++) {
      final left = i * (width + gap);
      final bar = calendarBar(days[i], goal);

      switch (bar.kind) {
        case CalendarBarKind.blank:
          break;
        case CalendarBarKind.future:
          canvas.drawCircle(
            Offset(left + width / 2, size.height - _dotRadius),
            _dotRadius,
            Paint()..color = muted,
          );
        case CalendarBarKind.emptySlot:
          canvas.drawRect(
            Rect.fromLTWH(left, 0, width, size.height),
            Paint()..color = slot,
          );
        case CalendarBarKind.normal ||
              CalendarBarKind.today ||
              CalendarBarKind.muted ||
              CalendarBarKind.over:
          final height = bar.height * size.height;
          canvas.drawRect(
            Rect.fromLTWH(left, size.height - height, width, height),
            Paint()..color = _colorOf(bar.kind),
          );
      }
    }

    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      Paint()
        ..color = line
        ..strokeWidth = 1,
    );
  }

  Color _colorOf(CalendarBarKind kind) {
    return switch (kind) {
      CalendarBarKind.today => today,
      CalendarBarKind.muted => muted,
      CalendarBarKind.over => over,
      _ => normal,
    };
  }

  @override
  bool shouldRepaint(CalendarBarsPainter oldDelegate) {
    return !identical(days, oldDelegate.days) ||
        goal != oldDelegate.goal ||
        normal != oldDelegate.normal;
  }
}
