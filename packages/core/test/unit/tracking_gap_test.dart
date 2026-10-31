import 'package:cat_calories_core/features/calorie_tracking/domain/tracking_gap.dart';
import 'package:cat_calories_core/features/calorie_tracking/sync/tracking_gap_sync_adapter.dart';
import 'package:test/test.dart';

void main() {
  final now = DateTime(2026, 10, 10, 12);
  final start = DateTime(2026, 10, 9, 18);
  final end = DateTime(2026, 10, 9, 23, 30);

  TrackingGap gap({String? description, DateTime? deletedAt}) => TrackingGap(
        id: 'g1',
        profileId: 'p1',
        startedAt: start,
        endedAt: end,
        description: description,
        createdAt: now,
        updatedAt: now,
        deletedAt: deletedAt,
      );

  group('trackingGapError', () {
    test('accepts a closed period in the past', () {
      expect(trackingGapError(start, end, now), isNull);
    });

    test('accepts a gap ending right now', () {
      expect(trackingGapError(start, now, now), isNull);
    });

    test('rejects an end in the future', () {
      final tomorrow = now.add(const Duration(days: 1));

      expect(trackingGapError(start, tomorrow, now), isNotNull);
    });

    test('rejects an end before the start', () {
      expect(trackingGapError(end, start, now), isNotNull);
    });

    test('rejects a period of no length', () {
      expect(trackingGapError(start, start, now), isNotNull);
    });
  });

  group('wholeDayBounds', () {
    test('covers a past day from midnight to midnight', () {
      final (from, to) = wholeDayBounds(DateTime(2026, 10, 9, 15), now);

      expect(from, DateTime(2026, 10, 9));
      expect(to, DateTime(2026, 10, 10));
    });

    test('stops today at the current moment', () {
      final (_, to) = wholeDayBounds(DateTime(2026, 10, 10), now);

      expect(to, now);
    });
  });

  group('TrackingGapSyncAdapter', () {
    final adapter = TrackingGapSyncAdapter();

    test('entityType is tracking_gap', () {
      expect(adapter.entityType, 'tracking_gap');
    });

    test('the payload round-trips every field', () {
      final deletedAt = DateTime(2026, 10, 10, 11);
      final restored = adapter.fromSyncPayload(adapter
          .toSyncPayload(gap(description: 'Dinner out', deletedAt: deletedAt)));

      expect(restored.id, 'g1');
      expect(restored.profileId, 'p1');
      expect(restored.startedAt, start);
      expect(restored.endedAt, end);
      expect(restored.description, 'Dinner out');
      expect(restored.createdAt, now);
      expect(restored.updatedAt, now);
      expect(restored.deletedAt, deletedAt);
    });

    test('a missing description stays missing', () {
      final restored = adapter.fromSyncPayload(adapter.toSyncPayload(gap()));

      expect(restored.description, isNull);
      expect(restored.deletedAt, isNull);
    });

    test('scope is the profile and identifier is the id', () {
      expect(adapter.extractScope(gap()), 'p1');
      expect(adapter.extractIdentifier(gap()), 'g1');
    });
  });
}
