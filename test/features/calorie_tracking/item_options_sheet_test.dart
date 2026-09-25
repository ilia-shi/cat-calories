import 'package:cat_calories/common/widgets/color_label_dot.dart';
import 'package:cat_calories/common/widgets/color_label_picker.dart';
import 'package:cat_calories/features/calorie_tracking/ui/widgets/item_options_sheet.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/calorie_record.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/color_label.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Taken from the palette instead of named: these tests are about the sheet's
  // preview dot and its picker, not about which colours the palette holds.
  final somePreset = ColorLabelPreset.values.first;
  final lastPreset = ColorLabelPreset.values.last;

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

  late List<ColorLabel?> changes;

  setUp(() {
    changes = [];
  });

  Future<void> pumpSheet(WidgetTester tester, CalorieRecord item) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ItemOptionsSheet(
            item: item,
            mealTitle: null,
            canMoveToMeal: false,
            onAdjustWeight: () {},
            onEditValues: () {},
            onEdit: () {},
            onToggleEaten: () {},
            onMoveToMeal: () {},
            onRemoveFromMeal: () {},
            onDelete: () {},
            onColorLabelChanged: changes.add,
          ),
        ),
      ),
    );
  }

  testWidgets('preview shows the dot for a labelled record', (tester) async {
    await pumpSheet(
      tester,
      record(colorLabel: somePreset.color, description: 'Porridge'),
    );

    expect(find.byType(ColorLabelDot), findsOneWidget);
    expect(find.text('+320 kcal'), findsOneWidget);
  });

  testWidgets('preview shows the dot without a description', (tester) async {
    await pumpSheet(tester, record(colorLabel: somePreset.color));

    expect(find.byType(ColorLabelDot), findsOneWidget);
  });

  testWidgets('preview shows no dot when unlabelled', (tester) async {
    await pumpSheet(tester, record(description: 'Porridge'));

    expect(find.byType(ColorLabelDot), findsNothing);
  });

  testWidgets('tapping a swatch reports the color and marks it selected',
      (tester) async {
    await pumpSheet(tester, record(description: 'Porridge'));
    expect(find.byType(ColorLabelDot), findsNothing);

    await tester.tap(find.bySemanticsLabel(lastPreset.name));
    await tester.pump();

    expect(changes, [lastPreset.color]);
    // Check mark on the chosen swatch + the dot now in the preview.
    expect(find.byIcon(Icons.check), findsOneWidget);
    expect(find.byType(ColorLabelDot), findsOneWidget);
  });

  testWidgets('tapping no-color removes an existing label', (tester) async {
    await pumpSheet(tester, record(colorLabel: lastPreset.color));

    await tester.tap(find.bySemanticsLabel('No color'));
    await tester.pump();

    expect(changes, [null]);
    expect(find.byIcon(Icons.check), findsNothing);
    expect(find.byType(ColorLabelDot), findsNothing);
  });

  testWidgets('the sheet stays open after changing the label', (tester) async {
    await pumpSheet(tester, record(description: 'Porridge'));

    await tester.tap(find.bySemanticsLabel(lastPreset.name));
    await tester.pumpAndSettle();

    expect(find.text('Delete Entry'), findsOneWidget);
    // The picker used to sit under a "Color label" heading, dropped when the
    // palette was pared down — the swatches under the option tiles say it.
    expect(find.byType(ColorLabelPicker), findsOneWidget);
  });

  testWidgets('every swatch is reachable without scrolling', (tester) async {
    // This used to drag the row sideways to reach a swatch past the edge, back
    // when the palette was long enough to overflow. Six presets fit any phone,
    // so there is nothing to scroll to here; the picker's own test covers the
    // scrolling itself, on a viewport narrow enough to still need it.
    await pumpSheet(tester, record(description: 'Porridge'));

    await tester.tap(find.bySemanticsLabel(lastPreset.name));
    await tester.pump();

    expect(changes, [lastPreset.color]);
  });
}
