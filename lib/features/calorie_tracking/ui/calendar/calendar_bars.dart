import 'package:cat_calories/common/theme/colors.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/calendar_cells.dart';
import 'package:flutter/material.dart';

/// One bar per day of a period, with the goal line at half height when the
/// bars have a goal.
class CalendarBars extends StatelessWidget {
  final List<CalendarBar> bars;
  final bool showGoalLine;
  final double height;

  const CalendarBars({
    super.key,
    required this.bars,
    required this.showGoalLine,
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
          bars: bars,
          showGoalLine: showGoalLine,
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

  final List<CalendarBar> bars;
  final bool showGoalLine;
  final Color normal;
  final Color today;
  final Color muted;
  final Color over;
  final Color slot;
  final Color line;

  const CalendarBarsPainter({
    required this.bars,
    required this.showGoalLine,
    required this.normal,
    required this.today,
    required this.muted,
    required this.over,
    required this.slot,
    required this.line,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final gap = bars.length > 7 ? 1.0 : 2.0;
    final width = (size.width - gap * (bars.length - 1)) / bars.length;

    for (var i = 0; i < bars.length; i++) {
      final left = i * (width + gap);
      final bar = bars[i];

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

    if (showGoalLine) {
      canvas.drawLine(
        Offset(0, size.height / 2),
        Offset(size.width, size.height / 2),
        Paint()
          ..color = line
          ..strokeWidth = 1,
      );
    }
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
    return !identical(bars, oldDelegate.bars) ||
        showGoalLine != oldDelegate.showGoalLine ||
        normal != oldDelegate.normal;
  }
}
