import 'package:cat_calories/features/calorie_tracking/ui/widgets/history/move_meal_day_sheet.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/calorie_record.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/meal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  DateTime dayFromToday(int offset) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day + offset);
  }

  CalorieRecord record({
    required String id,
    DateTime? eatenAt,
    DateTime? plannedFor,
  }) {
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
      plannedFor: plannedFor,
    );
  }

  Meal meal({DateTime? plannedFor}) => Meal(
        id: 'm1',
        profileId: 'p1',
        title: 'Chicken curry',
        createdAt: dayFromToday(-1),
        plannedFor: plannedFor,
      );

  Future<List<DateTime?>?> openSheet(
    WidgetTester tester, {
    required Meal subject,
    required List<CalorieRecord> members,
    required Future<void> Function(WidgetTester tester) act,
  }) async {
    List<DateTime?>? result;

    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: ElevatedButton(
            onPressed: () async {
              result = await MoveMealDaySheet.show(
                context,
                meal: subject,
                members: members,
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await act(tester);
    await tester.pumpAndSettle();
    return result;
  }

  testWidgets('moves the meal to the chosen day', (tester) async {
    final result = await openSheet(
      tester,
      subject: meal(plannedFor: dayFromToday(1)),
      members: [record(id: 'a1', plannedFor: dayFromToday(1))],
      act: (tester) async {
        await tester.tap(find.text('Today'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Move'));
      },
    );

    expect(result, isNotNull);
    expect(result!.single, dayFromToday(0));
  });

  testWidgets('untying the meal from any day is a choice, not a dismissal',
      (tester) async {
    final result = await openSheet(
      tester,
      subject: meal(plannedFor: dayFromToday(1)),
      members: [record(id: 'a1', plannedFor: dayFromToday(1))],
      act: (tester) async {
        // Tapping the selected chip clears the day.
        await tester.tap(find.text('Tomorrow'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Move'));
      },
    );

    expect(result, isNotNull, reason: 'the sheet was not dismissed');
    expect(result!.single, isNull);
  });

  testWidgets('backing out returns nothing at all', (tester) async {
    final result = await openSheet(
      tester,
      subject: meal(plannedFor: dayFromToday(1)),
      members: [record(id: 'a1', plannedFor: dayFromToday(1))],
      act: (tester) async {
        await tester.tapAt(const Offset(20, 20));
      },
    );

    expect(result, isNull);
  });

  testWidgets('a meal nobody has eaten from moves without a warning',
      (tester) async {
    await openSheet(
      tester,
      subject: meal(plannedFor: dayFromToday(1)),
      members: [
        record(id: 'a1', plannedFor: dayFromToday(1)),
        record(id: 'a2', plannedFor: dayFromToday(1)),
      ],
      act: (tester) async {
        expect(find.textContaining('already eaten'), findsNothing);
        await tester.tap(find.text('Move'));
      },
    );
  });

  testWidgets('a partly eaten meal says what will be left behind',
      (tester) async {
    await openSheet(
      tester,
      subject: meal(plannedFor: dayFromToday(-1)),
      members: [
        record(id: 'a1', plannedFor: dayFromToday(-1)),
        record(id: 'a2', plannedFor: dayFromToday(-1)),
        record(id: 'a3', eatenAt: dayFromToday(-1).add(const Duration(hours: 13))),
      ],
      act: (tester) async {
        await tester.tap(find.text('Today'));
        await tester.pumpAndSettle();

        expect(
          find.text('Moves 2 of 3 ingredients to Today — '
              '1 already eaten stay on Yesterday.'),
          findsOneWidget,
        );
        await tester.tap(find.text('Move'));
      },
    );
  });

  testWidgets('eaten ingredients spread over days are not pinned to one',
      (tester) async {
    await openSheet(
      tester,
      subject: meal(plannedFor: dayFromToday(-1)),
      members: [
        record(id: 'a1', plannedFor: dayFromToday(-1)),
        record(id: 'a2', eatenAt: dayFromToday(-1).add(const Duration(hours: 13))),
        record(id: 'a3', eatenAt: dayFromToday(-2).add(const Duration(hours: 19))),
      ],
      act: (tester) async {
        await tester.tap(find.text('Today'));
        await tester.pumpAndSettle();

        expect(
          find.text('Moves 1 of 3 ingredients to Today — '
              '2 already eaten stay on the days they were eaten.'),
          findsOneWidget,
        );
        await tester.tap(find.text('Move'));
      },
    );
  });
}
