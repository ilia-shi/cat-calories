import 'package:cat_calories_core/features/metrics/domain/day_metric.dart';
import 'package:cat_calories_core/features/metrics/domain/day_metric_entry.dart';
import 'package:cat_calories_core/features/metrics/sync/day_metric_sync_adapter.dart';
import 'package:test/test.dart';

void main() {
  final now = DateTime(2026, 11, 1, 12);

  DayMetricEntry entry({double value = 9000, String? note, DateTime? deletedAt}) {
    final manual = DayMetricEntry.manual(
      profileId: 'p1',
      metric: DayMetric.steps,
      day: DateTime(2026, 10, 9, 23, 30),
      value: value,
      note: note,
      now: now,
    );

    return deletedAt == null ? manual : manual.markedDeleted(deletedAt);
  }

  group('dayMetricEntryId', () {
    String id({
      String profileId = 'p1',
      String metricKey = 'steps',
      String day = '2026-10-09',
      String source = 'manual',
    }) =>
        dayMetricEntryId(
          profileId: profileId,
          metricKey: metricKey,
          day: day,
          source: source,
        );

    test('is the same on every call', () {
      expect(id(), id());
    });

    test('has a pinned value, so a change cannot orphan stored rows', () {
      expect(id(), '2ef15bdc-f630-5cfe-abb8-aeb6f92b3d71');
    });

    test('differs by each key field', () {
      final others = {
        id(profileId: 'p2'),
        id(metricKey: 'sleep_minutes'),
        id(day: '2026-10-10'),
        id(source: 'com.polar.flow'),
      };

      expect(others, hasLength(4));
      expect(others, isNot(contains(id())));
    });
  });

  group('day key', () {
    test('zero-pads, so text order equals date order', () {
      expect(dayMetricKey(DateTime(2026, 3, 7, 23, 59)), '2026-03-07');
    });

    test('comes from calendar fields of a UTC moment as well', () {
      expect(dayMetricKey(DateTime.utc(2026, 3, 7, 23, 59)), '2026-03-07');
    });

    test('parses back to local midnight', () {
      expect(dayFromMetricKey('2026-03-07'), DateTime(2026, 3, 7));
    });
  });

  group('DayMetricEntry.manual', () {
    test('keys the entry to the calendar day and the manual source', () {
      final saved = entry();

      expect(saved.day, '2026-10-09');
      expect(saved.source, manualMetricSource);
      expect(saved.metric, DayMetric.steps);
      expect(
        saved.id,
        dayMetricEntryId(
          profileId: 'p1',
          metricKey: 'steps',
          day: '2026-10-09',
          source: manualMetricSource,
        ),
      );
    });
  });

  group('unknown metric', () {
    test('fromKey returns null', () {
      expect(DayMetric.fromKey('heart_rate'), isNull);
    });

    test('an entry keeps its key and has no metric', () {
      final json = entry().toJson()..['metric_key'] = 'heart_rate';
      final pulled = DayMetricEntry.fromJson(json);

      expect(pulled.metric, isNull);
      expect(pulled.metricKey, 'heart_rate');
    });
  });

  group('input', () {
    test('stores whole numbers', () {
      expect(DayMetric.steps.fromInput(9000.4), 9000);
      expect(DayMetric.burnedKcal.fromInput(2399.6), 2400);
    });

    test('sleep is typed in hours and stored in minutes', () {
      expect(DayMetric.sleepMinutes.fromInput(7.5), 450);
      expect(DayMetric.sleepMinutes.fromInput(0.26), 16);
    });

    test('toInput brings back the same stored value', () {
      for (var minutes = 0; minutes <= 1440; minutes++) {
        final typed = double.parse(
          DayMetric.sleepMinutes.toInput(minutes.toDouble()),
        );

        expect(DayMetric.sleepMinutes.fromInput(typed), minutes);
      }
    });

    test('toInput drops trailing zeros without touching whole tens', () {
      expect(DayMetric.sleepMinutes.toInput(450), '7.5');
      expect(DayMetric.sleepMinutes.toInput(600), '10');
      expect(DayMetric.steps.toInput(1000), '1000');
    });
  });

  group('format', () {
    test('sleep shows hours and minutes', () {
      expect(DayMetric.sleepMinutes.format(450), '7 h 30 min');
      expect(DayMetric.sleepMinutes.format(420), '7 h');
      expect(DayMetric.sleepMinutes.format(30), '30 min');
      expect(DayMetric.sleepMinutes.format(0), '0 min');
    });

    test('steps and kcal have no decimals', () {
      expect(DayMetric.steps.format(9500), '9500');
      expect(DayMetric.steps.format(0), '0');
      expect(DayMetric.burnedKcal.format(2400), '2400 kcal');
    });
  });

  group('dayMetricError', () {
    final today = DateTime(2026, 11, 1);

    test('accepts today, a past day and zero', () {
      expect(dayMetricError(DayMetric.steps, 0, today, now), isNull);
      expect(
        dayMetricError(DayMetric.steps, 9000, DateTime(2020), now),
        isNull,
      );
    });

    test('rejects a future day', () {
      expect(
        dayMetricError(DayMetric.steps, 1, DateTime(2026, 11, 2), now),
        isNotNull,
      );
    });

    test('rejects a negative value', () {
      expect(dayMetricError(DayMetric.burnedKcal, -1, today, now), isNotNull);
    });

    test('limits sleep to 24 hours', () {
      expect(dayMetricError(DayMetric.sleepMinutes, 1440, today, now), isNull);
      expect(
        dayMetricError(DayMetric.sleepMinutes, 1441, today, now),
        isNotNull,
      );
    });

    test('does not limit steps at that number', () {
      expect(dayMetricError(DayMetric.steps, 30000, today, now), isNull);
    });
  });

  group('DayMetricSyncAdapter', () {
    final adapter = DayMetricSyncAdapter();

    test('uses the day_metric entity type and scopes by profile', () {
      expect(adapter.entityType, 'day_metric');
      expect(adapter.extractScope(entry()), 'p1');
      expect(adapter.extractIdentifier(entry()), entry().id);
      expect(adapter.extractUpdatedAt(entry()), now);
    });

    test('round-trips every field, a soft delete and a note included', () {
      final deleted = entry(
        note: 'Long walk',
        deletedAt: DateTime(2026, 11, 1, 13),
      );
      final pulled = adapter.fromSyncPayload(adapter.toSyncPayload(deleted));

      expect(pulled.toJson(), deleted.toJson());
      expect(pulled.isDeleted, isTrue);
      expect(pulled.updatedAt, DateTime(2026, 11, 1, 13));
    });

    test('accepts a whole number from JSON as the value', () {
      final json = entry().toJson()..['value'] = 9000;

      expect(DayMetricEntry.fromJson(json).value, 9000.0);
    });
  });
}
