import 'package:cat_calories/common/widgets/color_label_dot.dart';
import 'package:cat_calories/features/calorie_tracking/ui/widgets/history/calorie_record_row.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/calorie_record.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/color_label.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  CalorieRecord record({ColorLabel? colorLabel, String? description}) =>
      CalorieRecord(
        id: 'r1',
        value: 320,
        description: description,
        sortOrder: 0,
        eatenAt: DateTime(2026, 7, 25, 12, 30),
        createdAt: DateTime(2026, 7, 25, 12, 30),
        profileId: 'p1',
        wakingPeriodId: null,
        colorLabel: colorLabel,
      );

  Future<void> pumpRow(WidgetTester tester, CalorieRecord item) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CalorieRecordRow(
            item: item,
            isSelected: false,
            isLast: true,
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
}
