import 'package:cat_calories/features/calorie_tracking/ui/widgets/history/meal_picker_sheet.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/calorie_record.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/meal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  CalorieRecord record({
    String id = 'r1',
    String? description,
    double value = 220,
    bool eaten = true,
    String? mealId,
  }) {
    return CalorieRecord(
      id: id,
      value: value,
      description: description,
      sortOrder: 0,
      eatenAt: eaten ? DateTime(2026, 7, 25, 12, 30) : null,
      createdAt: DateTime(2026, 7, 25, 12, 30),
      profileId: 'p1',
      wakingPeriodId: null,
      mealId: mealId,
    );
  }

  Meal meal(String id, String title) => Meal(
        id: id,
        profileId: 'p1',
        title: title,
        createdAt: DateTime(2026, 7, 25, 12),
      );

  Future<void> pumpSheet(
    WidgetTester tester, {
    required List<Meal> meals,
    Map<String, List<CalorieRecord>> membersByMeal = const {},
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MealPickerSheet(
            item: record(description: 'Rice'),
            meals: meals,
            membersByMeal: membersByMeal,
          ),
        ),
      ),
    );
  }

  testWidgets('shows each meal with its item count and calories',
      (tester) async {
    await pumpSheet(
      tester,
      meals: [meal('m1', 'Lunch bowl'), meal('m2', 'Dinner')],
      membersByMeal: {
        'm1': [
          record(id: 'a', value: 320, mealId: 'm1'),
          record(id: 'b', value: 220, mealId: 'm1'),
        ],
      },
    );

    expect(find.text('Lunch bowl'), findsOneWidget);
    expect(find.text('2 items · 540 kcal'), findsOneWidget);
    expect(find.text('No items yet'), findsOneWidget,
        reason: 'a meal planned ahead has no members yet');
  });

  testWidgets('marks a meal with uneaten members as planned', (tester) async {
    await pumpSheet(
      tester,
      meals: [meal('m1', 'Lunch bowl')],
      membersByMeal: {
        'm1': [record(id: 'a', value: 320, eaten: false, mealId: 'm1')],
      },
    );

    expect(find.text('planned'), findsOneWidget);
  });

  testWidgets('pops with the tapped meal', (tester) async {
    Meal? picked;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              picked = await MealPickerSheet.show(
                context,
                item: record(),
                meals: [meal('m1', 'Lunch bowl'), meal('m2', 'Dinner')],
                membersByMeal: const {},
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dinner'));
    await tester.pumpAndSettle();

    expect(picked?.id, 'm2');
  });

  testWidgets('dismissing without a choice yields null', (tester) async {
    Object? picked = 'untouched';
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              picked = await MealPickerSheet.show(
                context,
                item: record(),
                meals: [meal('m1', 'Lunch bowl')],
                membersByMeal: const {},
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    Navigator.of(tester.element(find.text('Lunch bowl'))).pop();
    await tester.pumpAndSettle();

    expect(picked, isNull);
  });

  testWidgets('search appears only past the threshold and filters the list',
      (tester) async {
    await pumpSheet(
      tester,
      meals: [for (int i = 0; i < 9; i++) meal('m$i', 'Meal $i')],
    );

    expect(find.byType(TextField), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'meal 7');
    await tester.pump();

    expect(find.text('Meal 7'), findsOneWidget);
    expect(find.text('Meal 3'), findsNothing);
  });

  testWidgets('no search field for a short list', (tester) async {
    await pumpSheet(tester, meals: [meal('m1', 'Lunch bowl')]);

    expect(find.byType(TextField), findsNothing);
  });
}
