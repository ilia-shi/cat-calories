import 'package:cat_calories/features/calorie_tracking/ui/widgets/history/date_group_card.dart';
import 'package:cat_calories/features/calorie_tracking/ui/widgets/history/day_summary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

void main() {
  DateTime dayFromToday(int offset) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day + offset);
  }

  DaySummary summary({
    double eaten = 0,
    double planned = 0,
    int items = 0,
    int plannedItems = 0,
  }) {
    return DaySummary()
      ..totalEaten = eaten
      ..positiveSum = eaten > 0 ? eaten : 0
      ..itemCount = items
      ..plannedKcal = planned
      ..plannedItemCount = plannedItems;
  }

  Future<void> pumpCard(
    WidgetTester tester, {
    required DateTime date,
    required DaySummary daySummary,
    VoidCallback? onPlanMeal,
  }) {
    return tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: DateGroupCard(
            date: date,
            summary: daySummary,
            isExpanded: false,
            onToggle: () {},
            dayItems: const [],
            onPlanMeal: onPlanMeal ?? () {},
          ),
        ),
      ),
    ));
  }

  final planAction = find.byTooltip('Plan a meal for this day');

  testWidgets('a day with only a plan leads with the planned figure',
      (tester) async {
    await pumpCard(
      tester,
      date: dayFromToday(2),
      daySummary: summary(planned: 720, items: 3, plannedItems: 3),
    );

    expect(find.text('720'), findsOneWidget);
    expect(find.text('kcal planned'), findsOneWidget);
    expect(find.text('kcal'), findsNothing);
  });

  testWidgets('a day with both shows what was eaten and the plan beside it',
      (tester) async {
    await pumpCard(
      tester,
      date: dayFromToday(0),
      daySummary: summary(eaten: 1200, planned: 500, items: 5, plannedItems: 2),
    );

    expect(find.text('1200'), findsOneWidget);
    expect(find.text('kcal'), findsOneWidget);
    expect(find.text('500 planned'), findsOneWidget);
  });

  testWidgets('a plain past day shows no planned figures at all',
      (tester) async {
    await pumpCard(
      tester,
      date: dayFromToday(-3),
      daySummary: summary(eaten: 1800, items: 6),
    );

    expect(find.text('1800'), findsOneWidget);
    expect(find.text('kcal'), findsOneWidget);
    expect(find.textContaining('planned'), findsNothing);
  });

  testWidgets('names today, yesterday and tomorrow', (tester) async {
    await pumpCard(
      tester,
      date: dayFromToday(0),
      daySummary: summary(eaten: 100, items: 1),
    );
    expect(find.text('Today'), findsOneWidget);

    await pumpCard(
      tester,
      date: dayFromToday(-1),
      daySummary: summary(eaten: 100, items: 1),
    );
    expect(find.text('Yesterday'), findsOneWidget);

    await pumpCard(
      tester,
      date: dayFromToday(1),
      daySummary: summary(planned: 100, items: 1, plannedItems: 1),
    );
    expect(find.text('Tomorrow'), findsOneWidget);
  });

  /// The date tile, found through the month label only it renders.
  ShapeDecoration badgeDecoration(WidgetTester tester, DateTime date) {
    final month = DateFormat('MMM').format(date).toUpperCase();
    final container = tester.widget<Container>(
      find
          .ancestor(of: find.text(month), matching: find.byType(Container))
          .first,
    );
    return container.decoration! as ShapeDecoration;
  }

  testWidgets('today and the days ahead can be planned onto', (tester) async {
    await pumpCard(
      tester,
      date: dayFromToday(0),
      daySummary: summary(eaten: 900, items: 4),
    );
    expect(planAction, findsOneWidget);

    await pumpCard(
      tester,
      date: dayFromToday(3),
      daySummary: summary(planned: 400, items: 2, plannedItems: 2),
    );
    expect(planAction, findsOneWidget);
  });

  testWidgets('a day already gone offers no planning', (tester) async {
    await pumpCard(
      tester,
      date: dayFromToday(-1),
      daySummary: summary(eaten: 1500, items: 5),
    );

    expect(
      planAction,
      findsNothing,
      reason: 'planning a day that has passed is not a thing to offer',
    );
  });

  testWidgets('the plan action reports the day it belongs to', (tester) async {
    var planned = 0;
    await pumpCard(
      tester,
      date: dayFromToday(2),
      daySummary: summary(planned: 400, items: 2, plannedItems: 2),
      onPlanMeal: () => planned++,
    );

    await tester.tap(planAction);
    await tester.pumpAndSettle();

    expect(planned, 1);
  });

  testWidgets('a day still to come is outlined, not filled', (tester) async {
    final date = dayFromToday(2);
    await pumpCard(
      tester,
      date: date,
      daySummary: summary(planned: 400, items: 2, plannedItems: 2),
    );

    final decoration = badgeDecoration(tester, date);

    expect(decoration.gradient, isNull, reason: 'the fill is today\'s alone');
    expect(decoration.color, Colors.transparent);
    expect((decoration.shape as OutlinedBorder).side.style, BorderStyle.solid);
  });

  testWidgets('today keeps its filled badge', (tester) async {
    final date = dayFromToday(0);
    await pumpCard(
      tester,
      date: date,
      daySummary: summary(eaten: 900, items: 4),
    );

    final decoration = badgeDecoration(tester, date);

    expect(decoration.gradient, isNotNull);
    expect((decoration.shape as OutlinedBorder).side.style, BorderStyle.none);
  });
}
