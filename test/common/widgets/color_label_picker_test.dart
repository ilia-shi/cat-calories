import 'package:cat_calories/common/widgets/color_label_picker.dart';
import 'package:cat_calories/common/widgets/horizontal_drag_scroll_area.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/color_label.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<ColorLabel?> pumpAndTap(
    WidgetTester tester, {
    required ColorLabel? value,
    required String tapSemanticLabel,
  }) async {
    ColorLabel? picked;
    var changed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ColorLabelPicker(
            value: value,
            onChanged: (color) {
              picked = color;
              changed = true;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.bySemanticsLabel(tapSemanticLabel));
    await tester.pump();

    expect(changed, isTrue, reason: 'onChanged should have fired');
    return picked;
  }

  testWidgets('offers a no-color option plus every preset', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ColorLabelPicker(value: null, onChanged: (_) {}),
        ),
      ),
    );

    expect(find.byType(InkWell),
        findsNWidgets(ColorLabelPreset.values.length + 1));
    expect(find.bySemanticsLabel('No color'), findsOneWidget);
    expect(find.bySemanticsLabel('teal'), findsOneWidget);
  });

  testWidgets('tapping a swatch reports that preset color', (tester) async {
    final picked = await pumpAndTap(tester,
        value: null, tapSemanticLabel: 'indigo');

    expect(picked, ColorLabelPreset.indigo.color);
  });

  testWidgets('tapping no-color clears the label', (tester) async {
    final picked = await pumpAndTap(tester,
        value: ColorLabelPreset.red.color, tapSemanticLabel: 'No color');

    expect(picked, isNull);
  });

  testWidgets('a non-preset color gets its own swatch', (tester) async {
    final custom = ColorLabel.tryParse('#123456')!;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ColorLabelPicker(value: custom, onChanged: (_) {}),
        ),
      ),
    );

    expect(find.bySemanticsLabel('Custom #123456'), findsOneWidget);
    expect(find.byType(InkWell),
        findsNWidgets(ColorLabelPreset.values.length + 2));
  });

  testWidgets('singleLine lays the swatches out in one scrolling row',
      (tester) async {
    ColorLabel? picked;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ColorLabelPicker(
            value: null,
            onChanged: (color) => picked = color,
            singleLine: true,
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ),
        ),
      ),
    );

    expect(find.byType(Wrap), findsNothing);
    expect(find.byType(HorizontalDragScrollArea), findsOneWidget);

    // The tail of the palette is off-viewport until the row is scrolled.
    await tester.dragUntilVisible(
      find.bySemanticsLabel('blueGrey'),
      find.byType(ColorLabelPicker),
      const Offset(-120, 0),
    );
    await tester.tap(find.bySemanticsLabel('blueGrey'));

    expect(picked, ColorLabelPreset.blueGrey.color);
  });

  testWidgets('singleLine scrolls by mouse drag without stealing swatch taps',
      (tester) async {
    ColorLabel? picked;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ColorLabelPicker(
            value: null,
            onChanged: (color) => picked = color,
            singleLine: true,
          ),
        ),
      ),
    );

    await tester.drag(find.byType(ColorLabelPicker), const Offset(-200, 0),
        kind: PointerDeviceKind.mouse);
    await tester.pumpAndSettle();

    final position =
        tester.state<ScrollableState>(find.byType(Scrollable)).position;
    expect(position.pixels, greaterThan(0));
    expect(picked, isNull, reason: 'a drag must not select a swatch');

    // A click without movement still picks, in the same spot the drag started.
    await tester.tap(find.bySemanticsLabel('grey'), kind: PointerDeviceKind.mouse);
    expect(picked, ColorLabelPreset.grey.color);
  });

  testWidgets('a preset value adds no extra swatch', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ColorLabelPicker(
            value: ColorLabelPreset.lime.color,
            onChanged: (_) {},
          ),
        ),
      ),
    );

    expect(find.byType(InkWell),
        findsNWidgets(ColorLabelPreset.values.length + 1));
    expect(find.byIcon(Icons.check), findsOneWidget);
  });
}
