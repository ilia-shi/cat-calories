import 'package:cat_calories/common/widgets/calculator/calorie_calculator_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late List<CalorieCalculatorResult> submitted;

  setUp(() {
    submitted = [];
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpSheet(
    WidgetTester tester, {
    double? initialCalories,
    double? initialWeightGrams,
    double? initialProteinGrams,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CalorieCalculatorSheet(
            submitLabel: 'Save',
            onSubmit: submitted.add,
            initialCalories: initialCalories,
            initialWeightGrams: initialWeightGrams,
            initialProteinGrams: initialProteinGrams,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a weighed record opens on the nutrition calculator and '
      'round-trips its values', (tester) async {
    await pumpSheet(
      tester,
      initialCalories: 300,
      initialWeightGrams: 150,
      initialProteinGrams: 15,
    );

    // The record's actual values, rebuilt from the per-100g prefill.
    expect(find.text('150'), findsWidgets);
    expect(find.text('300'), findsOneWidget);
    expect(find.text('15'), findsOneWidget);

    await tester.tap(find.text('Save'));
    await tester.pump();

    expect(submitted, hasLength(1));
    expect(submitted.single.calories, closeTo(300, 0.5));
    expect(submitted.single.weightGrams, 150);
    expect(submitted.single.proteinGrams, closeTo(15, 0.5));
  });

  testWidgets('a weightless record opens on quick add', (tester) async {
    await pumpSheet(tester, initialCalories: 250);

    expect(find.widgetWithText(TextField, '250'), findsOneWidget);

    await tester.tap(find.text('Save'));
    await tester.pump();

    expect(submitted.single.calories, 250);
    expect(submitted.single.weightGrams, isNull);
    expect(submitted.single.expression, '250');
  });

  testWidgets('adding starts empty with nothing to submit', (tester) async {
    await pumpSheet(tester);

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, isEmpty);

    await tester.tap(find.text('Save'));
    await tester.pump();

    expect(submitted, isEmpty);
  });
}
