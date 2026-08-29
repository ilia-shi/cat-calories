import 'package:cat_calories/features/calorie_tracking/ui/widgets/today_plan_row.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/calorie_record.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/meal.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/planned_meals.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  CalorieRecord record({required String id, double value = 250}) {
    return CalorieRecord(
      id: id,
      value: value,
      description: null,
      sortOrder: 0,
      eatenAt: null,
      createdAt: DateTime(2026, 8, 29, 9),
      profileId: 'p1',
      wakingPeriodId: null,
      mealId: 'm1',
      plannedFor: DateTime(2026, 8, 29),
    );
  }

  PlannedMeal planned(
    String title, {
    required List<CalorieRecord> records,
  }) {
    return PlannedMeal(
      meal: Meal(
        id: 'm1',
        profileId: 'p1',
        title: title,
        createdAt: DateTime(2026, 8, 28, 12),
        plannedFor: DateTime(2026, 8, 29),
      ),
      records: records,
    );
  }

  Future<void> pumpCard(
    WidgetTester tester,
    List<PlannedMeal> plan, {
    ValueChanged<PlannedMeal>? onEaten,
    ValueChanged<PlannedMeal>? onOpen,
  }) {
    return tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: TodayPlanCard(
          planned: plan,
          onEaten: onEaten ?? (_) {},
          onOpen: onOpen ?? (_) {},
        ),
      ),
    ));
  }

  testWidgets('lists each planned meal with its items and calories',
      (tester) async {
    await pumpCard(tester, [
      planned('Chicken curry', records: [
        record(id: 'a1', value: 400),
        record(id: 'a2', value: 220),
      ]),
    ]);

    expect(find.text('Planned for today'), findsOneWidget);
    expect(find.text('Chicken curry'), findsOneWidget);
    expect(find.text('2 items · 620 kcal'), findsOneWidget);
  });

  testWidgets('a single ingredient is one item, not one items', (tester) async {
    await pumpCard(tester, [
      planned('Porridge', records: [record(id: 'a1', value: 310)]),
    ]);

    expect(find.text('1 item · 310 kcal'), findsOneWidget);
  });

  testWidgets('the header totals the whole day\'s plan', (tester) async {
    await pumpCard(tester, [
      planned('Curry', records: [record(id: 'a1', value: 400)]),
      planned('Porridge', records: [record(id: 'a2', value: 310)]),
    ]);

    expect(find.text('710 kcal'), findsOneWidget);
  });

  testWidgets('eating one hands that meal back to the caller', (tester) async {
    PlannedMeal? eaten;
    final curry = planned('Curry', records: [record(id: 'a1')]);

    await pumpCard(tester, [curry], onEaten: (meal) => eaten = meal);
    await tester.tap(find.text('Eaten'));
    await tester.pumpAndSettle();

    expect(eaten, same(curry));
  });

  testWidgets('tapping the meal itself opens it instead of eating it',
      (tester) async {
    PlannedMeal? opened;
    var eaten = 0;
    final curry = planned('Curry', records: [record(id: 'a1')]);

    await pumpCard(
      tester,
      [curry],
      onEaten: (_) => eaten++,
      onOpen: (meal) => opened = meal,
    );
    await tester.tap(find.text('Curry'));
    await tester.pumpAndSettle();

    expect(opened, same(curry));
    expect(eaten, 0, reason: 'the row and its button are separate actions');
  });
}
