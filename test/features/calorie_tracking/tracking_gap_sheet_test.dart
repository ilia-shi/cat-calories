import 'package:cat_calories/features/calorie_tracking/ui/widgets/tracking_gap_sheet.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/tracking_gap.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final yesterday = DateTime.now().subtract(const Duration(days: 1));

  Future<List<TrackingGap>> pumpAndSave(
    WidgetTester tester, {
    required DateTime start,
    required DateTime end,
    TrackingGap? gap,
    String? description,
  }) async {
    final saved = <TrackingGap>[];

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: TrackingGapSheet(
          gap: gap,
          profileId: 'p1',
          initialStart: start,
          initialEnd: end,
          onSave: saved.add,
        ),
      ),
    ));
    if (description != null) {
      await tester.enterText(find.byType(TextField), description);
    }
    await tester.tap(find.text('Save'));
    await tester.pump();

    return saved;
  }

  testWidgets('shows the hint for the description', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: TrackingGapSheet(
          profileId: 'p1',
          initialStart: yesterday,
          initialEnd: yesterday.add(const Duration(hours: 2)),
          onSave: (_) {},
        ),
      ),
    ));

    expect(
      find.text('Roughly what did you eat? How hungry were you?'),
      findsOneWidget,
    );
  });

  testWidgets('a blank description saves as no description', (tester) async {
    final saved = await pumpAndSave(
      tester,
      start: yesterday,
      end: yesterday.add(const Duration(hours: 2)),
      description: '   ',
    );

    expect(saved.single.description, isNull);
    expect(saved.single.profileId, 'p1');
  });

  testWidgets('an end in the future is refused with a reason', (tester) async {
    final saved = await pumpAndSave(
      tester,
      start: yesterday,
      end: DateTime.now().add(const Duration(days: 1)),
    );

    expect(saved, isEmpty);
    expect(find.text('A gap cannot end in the future'), findsOneWidget);
  });

  testWidgets('an end before the start is refused with a reason',
      (tester) async {
    final saved = await pumpAndSave(
      tester,
      start: yesterday,
      end: yesterday.subtract(const Duration(hours: 1)),
    );

    expect(saved, isEmpty);
    expect(find.text('The start must be before the end'), findsOneWidget);
  });

  testWidgets('editing keeps the id and creation time', (tester) async {
    final createdAt = DateTime(2026, 1, 1);
    final saved = await pumpAndSave(
      tester,
      start: yesterday,
      end: yesterday.add(const Duration(hours: 2)),
      description: 'Dinner out',
      gap: TrackingGap(
        id: 'g1',
        profileId: 'p1',
        startedAt: yesterday,
        endedAt: yesterday.add(const Duration(hours: 2)),
        description: null,
        createdAt: createdAt,
        updatedAt: createdAt,
      ),
    );

    expect(saved.single.id, 'g1');
    expect(saved.single.createdAt, createdAt);
    expect(saved.single.description, 'Dinner out');
    expect(saved.single.updatedAt.isAfter(createdAt), isTrue);
  });
}
