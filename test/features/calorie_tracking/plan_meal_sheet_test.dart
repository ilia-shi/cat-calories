import 'package:cat_calories/features/calorie_tracking/ui/widgets/history/plan_meal_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

void main() {
  DateTime dayFromToday(int offset) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day + offset);
  }

  String dayLabel(DateTime day) => DateFormat('EEE d MMM').format(day);

  /// Opens the sheet over a bare screen and returns what it resolved to, so a
  /// test asserts on the PlanMealResult the caller would receive.
  Future<PlanMealResult?> openSheet(
    WidgetTester tester, {
    String? initialTitle,
    DateTime? fixedDay,
    required Future<void> Function(WidgetTester tester) act,
  }) async {
    PlanMealResult? result;
    var done = false;

    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: ElevatedButton(
            onPressed: () async {
              result = await PlanMealSheet.show(
                context,
                initialTitle: initialTitle,
                fixedDay: fixedDay,
              );
              done = true;
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

    expect(done, isTrue, reason: 'the sheet should have closed');
    return result;
  }

  testWidgets('offers today, tomorrow, the day after and the calendar',
      (tester) async {
    await openSheet(tester, act: (tester) async {
      expect(find.text('Plan a meal'), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Tomorrow'), findsOneWidget);
      expect(find.text(DateFormat('EEE').format(dayFromToday(2))),
          findsOneWidget);
      expect(find.text('Pick a day'), findsOneWidget);
      await tester.tap(find.text('Plan'));
    });
  });

  testWidgets('planning for today leaves the day empty', (tester) async {
    final result = await openSheet(tester, act: (tester) async {
      await tester.tap(find.text('Plan'));
    });

    expect(result, isNotNull);
    expect(
      result!.plannedFor,
      isNull,
      reason: 'today and no particular day are the same thing downstream',
    );
  });

  testWidgets('an unnamed meal is titled by the day it is for',
      (tester) async {
    final result = await openSheet(tester, act: (tester) async {
      await tester.tap(find.text('Tomorrow'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Plan'));
    });

    expect(result!.plannedFor, dayFromToday(1));
    expect(result.title, 'Meal for ${dayLabel(dayFromToday(1))}');
  });

  testWidgets('an unnamed meal for today is titled by today', (tester) async {
    final result = await openSheet(tester, act: (tester) async {
      await tester.tap(find.text('Plan'));
    });

    expect(result!.title, 'Meal for ${dayLabel(dayFromToday(0))}');
  });

  testWidgets('a typed name wins over the fallback', (tester) async {
    final result = await openSheet(tester, act: (tester) async {
      await tester.enterText(find.byType(TextField), '  Chicken curry  ');
      await tester.tap(find.text('Tomorrow'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Plan'));
    });

    expect(result!.title, 'Chicken curry');
    expect(result.plannedFor, dayFromToday(1));
  });

  testWidgets('cooking again starts from the source meal\'s name',
      (tester) async {
    final result = await openSheet(
      tester,
      initialTitle: 'Old curry',
      act: (tester) async {
        expect(find.text('Old curry'), findsOneWidget);
        await tester.tap(find.text('Plan'));
      },
    );

    expect(result!.title, 'Old curry');
  });

  testWidgets('planning from a day card states the day instead of asking',
      (tester) async {
    final result = await openSheet(
      tester,
      fixedDay: dayFromToday(4),
      act: (tester) async {
        expect(find.text('Tomorrow'), findsNothing,
            reason: 'the day was settled by the card that was tapped');
        expect(find.text('Pick a day'), findsNothing);
        expect(find.text(dayLabel(dayFromToday(4))), findsOneWidget);
        await tester.tap(find.text('Plan'));
      },
    );

    expect(result!.plannedFor, dayFromToday(4));
    expect(result.title, 'Meal for ${dayLabel(dayFromToday(4))}');
  });

  testWidgets('planning onto today from its own card stores no day',
      (tester) async {
    final result = await openSheet(
      tester,
      fixedDay: dayFromToday(0),
      act: (tester) async {
        expect(find.text('Today'), findsOneWidget);
        await tester.tap(find.text('Plan'));
      },
    );

    expect(result!.plannedFor, isNull);
  });

  testWidgets('backing out plans nothing', (tester) async {
    final result = await openSheet(tester, act: (tester) async {
      // Tapping the barrier above the sheet dismisses it.
      await tester.tapAt(const Offset(20, 20));
    });

    expect(result, isNull);
  });
}
