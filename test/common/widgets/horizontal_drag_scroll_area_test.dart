import 'package:cat_calories/common/widgets/horizontal_drag_scroll_area.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpStrip(WidgetTester tester) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: HorizontalDragScrollArea(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  for (var i = 0; i < 40; i++)
                    SizedBox(width: 60, height: 40, child: Text('item$i')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  ScrollPosition positionOf(WidgetTester tester) {
    return tester.state<ScrollableState>(find.byType(Scrollable)).position;
  }

  testWidgets('drags with a finger', (tester) async {
    await pumpStrip(tester);

    await tester.drag(find.byType(HorizontalDragScrollArea),
        const Offset(-200, 0), kind: PointerDeviceKind.touch);
    await tester.pumpAndSettle();

    expect(positionOf(tester).pixels, greaterThan(0));
  });

  testWidgets('drags with a mouse, which Flutter disables by default',
      (tester) async {
    await pumpStrip(tester);

    await tester.drag(find.byType(HorizontalDragScrollArea),
        const Offset(-200, 0), kind: PointerDeviceKind.mouse);
    await tester.pumpAndSettle();

    expect(positionOf(tester).pixels, greaterThan(0));
  });

  testWidgets('a vertical wheel scrolls the row sideways', (tester) async {
    await pumpStrip(tester);

    final pointer = TestPointer(1, PointerDeviceKind.mouse);
    final center = tester.getCenter(find.byType(HorizontalDragScrollArea));
    await tester.sendEventToBinding(pointer.hover(center));
    await tester.sendEventToBinding(pointer.scroll(const Offset(0, 140)));
    await tester.pump();

    expect(positionOf(tester).pixels, 140);
  });

  testWidgets('a horizontal wheel delta scrolls once, not twice',
      (tester) async {
    await pumpStrip(tester);

    final pointer = TestPointer(1, PointerDeviceKind.mouse);
    final center = tester.getCenter(find.byType(HorizontalDragScrollArea));
    await tester.sendEventToBinding(pointer.hover(center));
    await tester.sendEventToBinding(pointer.scroll(const Offset(90, 10)));
    await tester.pump();

    expect(positionOf(tester).pixels, 90);
  });

  testWidgets('inside a scrolling page the wheel moves the page, not the row',
      (tester) async {
    final pageController = ScrollController();
    addTearDown(pageController.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            controller: pageController,
            child: Column(
              children: [
                const SizedBox(height: 900),
                HorizontalDragScrollArea(
                  child: Row(
                    children: [
                      for (var i = 0; i < 40; i++)
                        SizedBox(width: 60, height: 40, child: Text('item$i')),
                    ],
                  ),
                ),
                const SizedBox(height: 900),
              ],
            ),
          ),
        ),
      ),
    );

    pageController.jumpTo(700);
    await tester.pump();

    final pointer = TestPointer(1, PointerDeviceKind.mouse);
    final center = tester.getCenter(find.byType(HorizontalDragScrollArea));
    await tester.sendEventToBinding(pointer.hover(center));
    await tester.sendEventToBinding(pointer.scroll(const Offset(0, 120)));
    await tester.pump();

    expect(pageController.offset, 820);
    final strip = tester.state<ScrollableState>(
        find.descendant(
          of: find.byType(HorizontalDragScrollArea),
          matching: find.byType(Scrollable),
        ));
    expect(strip.position.pixels, 0);

    // Dragging still moves the strip sideways.
    await tester.drag(find.byType(HorizontalDragScrollArea),
        const Offset(-150, 0), kind: PointerDeviceKind.mouse);
    await tester.pumpAndSettle();
    expect(strip.position.pixels, greaterThan(0));
  });

  testWidgets('the wheel clamps at both extents', (tester) async {
    await pumpStrip(tester);

    final pointer = TestPointer(1, PointerDeviceKind.mouse);
    final center = tester.getCenter(find.byType(HorizontalDragScrollArea));
    await tester.sendEventToBinding(pointer.hover(center));

    await tester.sendEventToBinding(pointer.scroll(const Offset(0, 100000)));
    await tester.pump();
    final position = positionOf(tester);
    expect(position.pixels, position.maxScrollExtent);

    await tester.sendEventToBinding(pointer.scroll(const Offset(0, -100000)));
    await tester.pump();
    expect(position.pixels, 0);
  });
}
