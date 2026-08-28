import 'package:cat_calories/features/calorie_tracking/ui/meal_edit_screen.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/meal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

void main() {
  DateTime dayFromToday(int offset) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day + offset);
  }

  Meal meal({DateTime? plannedFor, DateTime? eatenAt}) => Meal(
        id: 'm1',
        profileId: 'p1',
        title: 'Chicken curry',
        createdAt: DateTime(2026, 8, 20, 12),
        plannedFor: plannedFor,
        eatenAt: eatenAt,
      );

  testWidgets('offers the day chips for a meal nobody has eaten yet',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: MealEditScreen(meal())),
    );

    expect(find.text('Planned for'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Tomorrow'), findsOneWidget);
    expect(find.text('Pick a day'), findsOneWidget);
  });

  testWidgets('saving a chosen day returns it as plannedFor', (tester) async {
    MealEditResult? saved;

    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: ElevatedButton(
            onPressed: () async {
              saved = await MealEditScreen.push(context, meal());
            },
            child: const Text('open'),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tomorrow'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(saved, isNotNull);
    expect(saved!.plannedFor, dayFromToday(1));
  });

  testWidgets('tapping the chosen day again clears it back to no day',
      (tester) async {
    MealEditResult? saved;

    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: ElevatedButton(
            onPressed: () async {
              saved = await MealEditScreen.push(
                context,
                meal(plannedFor: dayFromToday(1)),
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tomorrow'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(saved, isNotNull);
    expect(saved!.plannedFor, isNull);
  });

  testWidgets('an eaten meal shows its planned day as text, not as chips',
      (tester) async {
    final day = DateTime(2026, 8, 20);

    await tester.pumpWidget(MaterialApp(
      home: MealEditScreen(
        meal(plannedFor: day, eatenAt: DateTime(2026, 8, 21, 19)),
      ),
    ));

    expect(
      find.text('Was planned for ${DateFormat('EEE d MMM').format(day)}'),
      findsOneWidget,
    );
    expect(find.text('Planned for'), findsNothing);
    expect(find.text('Tomorrow'), findsNothing);
  });

  testWidgets('an eaten meal that was never planned shows no day at all',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: MealEditScreen(meal(eatenAt: DateTime(2026, 8, 21, 19))),
    ));

    expect(find.textContaining('planned for'), findsNothing);
    expect(find.text('Planned for'), findsNothing);
  });

  testWidgets('the planned day alone enables Save', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: MealEditScreen(meal())),
    );

    final saveButton = find.widgetWithText(TextButton, 'Save');
    expect(
      tester.widget<TextButton>(saveButton).onPressed,
      isNull,
      reason: 'nothing edited yet',
    );

    await tester.tap(find.text('Today'));
    await tester.pumpAndSettle();

    expect(tester.widget<TextButton>(saveButton).onPressed, isNotNull);
  });
}
