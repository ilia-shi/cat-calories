import 'package:cat_calories/features/calorie_tracking/ui/widgets/history/meal_options_sheet.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/calorie_record.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/meal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  DateTime dayFromToday(int offset) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day + offset);
  }

  CalorieRecord record({required String id, DateTime? eatenAt}) {
    return CalorieRecord(
      id: id,
      value: 200,
      description: null,
      sortOrder: 0,
      eatenAt: eatenAt,
      createdAt: dayFromToday(-1),
      profileId: 'p1',
      wakingPeriodId: null,
      mealId: 'm1',
    );
  }

  Meal meal({DateTime? plannedFor, DateTime? eatenAt}) => Meal(
        id: 'm1',
        profileId: 'p1',
        title: 'Chicken curry',
        createdAt: dayFromToday(-1),
        plannedFor: plannedFor,
        eatenAt: eatenAt,
      );

  Future<void> pumpSheet(
    WidgetTester tester, {
    required Meal subject,
    required List<CalorieRecord> members,
    VoidCallback? onMoveToDay,
    VoidCallback? onMarkNotEaten,
  }) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: MealOptionsSheet(
          meal: subject,
          members: members,
          onCookingMode: () {},
          onDuplicate: () {},
          onEdit: () {},
          onMoveToDay: onMoveToDay ?? () {},
          onMarkEaten: () {},
          onMarkNotEaten: onMarkNotEaten ?? () {},
          onUngroup: () {},
          onDelete: () {},
        ),
      ),
    ));
  }

  testWidgets('a planned meal can be moved and marked eaten', (tester) async {
    await pumpSheet(
      tester,
      subject: meal(plannedFor: dayFromToday(1)),
      members: [record(id: 'a1')],
    );

    expect(find.text('Move to Another Day'), findsOneWidget);
    expect(find.text('Planned for Tomorrow'), findsOneWidget);
    expect(find.text('Mark Meal as Eaten'), findsOneWidget);
    expect(find.text('Mark as Not Eaten'), findsNothing);
  });

  testWidgets('a meal with no day yet is offered one', (tester) async {
    await pumpSheet(
      tester,
      subject: meal(),
      members: [record(id: 'a1')],
    );

    expect(find.text('Plan it for a specific day'), findsOneWidget);
  });

  testWidgets('an eaten meal offers no day to change', (tester) async {
    await pumpSheet(
      tester,
      subject: meal(plannedFor: dayFromToday(-1), eatenAt: dayFromToday(0)),
      members: [record(id: 'a1', eatenAt: dayFromToday(0))],
    );

    expect(
      find.text('Move to Another Day'),
      findsNothing,
      reason: 'the day it was eaten decides now, so the plan changes nothing',
    );
    expect(find.text('Mark as Not Eaten'), findsOneWidget);
    expect(find.text('Mark Meal as Eaten'), findsNothing);
  });

  testWidgets('a partly eaten meal offers both directions', (tester) async {
    await pumpSheet(
      tester,
      subject: meal(plannedFor: dayFromToday(-1)),
      members: [
        record(id: 'a1'),
        record(id: 'a2', eatenAt: dayFromToday(0)),
      ],
    );

    expect(find.text('Mark Meal as Eaten'), findsOneWidget);
    expect(find.text('Mark as Not Eaten'), findsOneWidget);
    expect(find.text('Move to Another Day'), findsOneWidget);
  });

  testWidgets('tapping move hands the action back to the caller',
      (tester) async {
    var moved = 0;
    await pumpSheet(
      tester,
      subject: meal(plannedFor: dayFromToday(1)),
      members: [record(id: 'a1')],
      onMoveToDay: () => moved++,
    );

    await tester.tap(find.text('Move to Another Day'));
    await tester.pumpAndSettle();

    expect(moved, 1);
  });
}
