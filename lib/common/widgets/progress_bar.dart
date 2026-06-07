import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ProgressPainter extends CustomPainter {
  final Color defaultCircleColor;
  final Color percentageCompletedCircleColor;
  final double completedPercentage;
  final double circleWidth;

  ProgressPainter(
      {required this.defaultCircleColor,
      required this.percentageCompletedCircleColor,
      required this.completedPercentage,
      required this.circleWidth});

  _getPaint(Color color) {
    return Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = circleWidth;
  }

  @override
  void paint(Canvas canvas, Size size) {
    Paint barPaint = _getPaint(defaultCircleColor);
    Paint progressPaint = _getPaint(percentageCompletedCircleColor);

    Offset center = Offset(size.width / 2, size.height / 2);
    double radius = min(size.width / 2, size.height / 2);
    canvas.drawCircle(center, radius, barPaint);


    double arcAngle = 2 * pi * (completedPercentage / 100);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -pi / 2,
        arcAngle, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
