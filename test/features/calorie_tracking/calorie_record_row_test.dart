import 'package:cat_calories/common/widgets/color_label_dot.dart';
import 'package:cat_calories/features/calorie_tracking/ui/widgets/calorie_record_row.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/calorie_record.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/color_label.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  CalorieRecord record({
    ColorLabel? colorLabel,
    String? description,
    bool eaten = true,
    double? weightGrams,
    double? costValue,
    String? costCurrency,
  }) =>
      CalorieRecord(
        id: 'r1',
        value: 320,
        description: description,
        sortOrder: 0,
        eatenAt: eaten ? DateTime(2026, 7, 25, 12, 30) : null,
        createdAt: DateTime(2026, 7, 25, 12, 30),
        profileId: 'p1',
        wakingPeriodId: null,
        colorLabel: colorLabel,
        weightGrams: weightGrams,
        costValue: costValue,
        costCurrency: costCurrency,
      );

  Future<void> pumpRow(
    WidgetTester tester,
    CalorieRecord item, {
    bool showDetails = false,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CalorieRecordRow(
            item: item,
            isSelected: false,
            isLast: true,
            showDetails: showDetails,
            onTap: () {},
            onLongPress: () {},
          ),
        ),
      ),
    );
  }

  testWidgets('shows a dot for a labelled record', (tester) async {
    final semantics = tester.ensureSemantics();

    await pumpRow(
      tester,
      record(colorLabel: ColorLabelPreset.teal.color, description: 'Porridge'),
    );

    expect(find.byType(ColorLabelDot), findsOneWidget);
    // The row's InkWell merges descendant semantics, so the dot's label is one
    // part of the announced row rather than a node of its own.
    expect(find.bySemanticsLabel(RegExp('Color label: teal')), findsOneWidget);
    expect(find.text('Porridge'), findsOneWidget);

    semantics.dispose();
  });

  testWidgets('shows no dot when the record is unlabelled', (tester) async {
    await pumpRow(tester, record(description: 'Porridge'));

    expect(find.byType(ColorLabelDot), findsNothing);
    expect(find.text('Porridge'), findsOneWidget);
  });

  testWidgets('keeps the dot on a record without a description',
      (tester) async {
    await pumpRow(tester, record(colorLabel: ColorLabelPreset.red.color));

    expect(find.byType(ColorLabelDot), findsOneWidget);
    expect(find.text('No description'), findsOneWidget);
  });

  testWidgets('a custom color falls back to its hex in semantics',
      (tester) async {
    final semantics = tester.ensureSemantics();

    await pumpRow(tester, record(colorLabel: ColorLabel.tryParse('#123456')));

    expect(find.bySemanticsLabel(RegExp('Color label: #123456')),
        findsOneWidget);

    semantics.dispose();
  });

  testWidgets('hides the weight of a planned record by default',
      (tester) async {
    await pumpRow(tester, record(eaten: false, weightGrams: 150));

    expect(find.text('150g'), findsNothing);
  });

  testWidgets('showDetails keeps the weight of a planned record visible',
      (tester) async {
    await pumpRow(
      tester,
      record(eaten: false, weightGrams: 150),
      showDetails: true,
    );

    expect(find.text('150g'), findsOneWidget);
  });

  testWidgets('shows the cost snapshot alongside the weight', (tester) async {
    await pumpRow(
      tester,
      record(weightGrams: 150, costValue: 1.2, costCurrency: 'EUR'),
      showDetails: true,
    );

    expect(find.text('150g'), findsOneWidget);
    expect(find.text('1.20 EUR'), findsOneWidget);
  });
}
