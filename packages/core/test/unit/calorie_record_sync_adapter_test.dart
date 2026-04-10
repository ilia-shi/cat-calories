import 'package:cat_calories_core/features/calorie_tracking/domain/calorie_record.dart';
import 'package:cat_calories_core/features/calorie_tracking/sync/calorie_record_sync_adapter.dart';
import 'package:test/test.dart';

void main() {
  late CalorieRecordSyncAdapter adapter;

  setUp(() {
    adapter = CalorieRecordSyncAdapter();
  });

  test('entityType is calorie_item', () {
    expect(adapter.entityType, 'calorie_item');
  });

  group('toSyncPayload / fromSyncPayload round-trip', () {
    test('preserves all fields', () {
      final now = DateTime(2025, 3, 15, 12, 0);
      final eaten = DateTime(2025, 3, 15, 11, 30);

      final record = CalorieRecord(
        id: 'rec-1',
        value: 350.5,
        description: 'Grilled chicken',
        sortOrder: 2,
        eatenAt: eaten,
        createdAt: now,
        updatedAt: now,
        profileId: 'profile-abc',
        wakingPeriodId: 'wp-1',
        weightGrams: 200.0,
        proteinGrams: 45.0,
        fatGrams: 12.5,
        carbGrams: 3.0,
        productId: 'prod-1',
      );

      final json = adapter.toSyncPayload(record);
      final restored = adapter.fromSyncPayload(json);

      expect(restored.id, record.id);
      expect(restored.value, record.value);
      expect(restored.description, record.description);
      expect(restored.sortOrder, record.sortOrder);
      expect(restored.eatenAt, record.eatenAt);
      expect(restored.createdAt, record.createdAt);
      expect(restored.updatedAt, record.updatedAt);
      expect(restored.profileId, record.profileId);
      expect(restored.wakingPeriodId, record.wakingPeriodId);
      expect(restored.weightGrams, record.weightGrams);
      expect(restored.proteinGrams, record.proteinGrams);
      expect(restored.fatGrams, record.fatGrams);
      expect(restored.carbGrams, record.carbGrams);
      expect(restored.productId, record.productId);
    });

    test('handles null optional fields', () {
      final now = DateTime(2025, 1, 1);
      final record = CalorieRecord(
        id: 'rec-2',
        value: 100.0,
        description: null,
        sortOrder: 0,
        eatenAt: null,
        createdAt: now,
        profileId: 'profile-1',
        wakingPeriodId: null,
      );

      final json = adapter.toSyncPayload(record);
      final restored = adapter.fromSyncPayload(json);

      expect(restored.eatenAt, isNull);
      expect(restored.weightGrams, isNull);
      expect(restored.proteinGrams, isNull);
      expect(restored.fatGrams, isNull);
      expect(restored.carbGrams, isNull);
      expect(restored.productId, isNull);
    });
  });

  group('extractIdentifier', () {
    test('returns entity id', () {
      final record = _makeRecord(id: 'rec-42');
      expect(adapter.extractIdentifier(record), 'rec-42');
    });

    test('throws when id is null', () {
      final record = _makeRecord(id: null);
      expect(() => adapter.extractIdentifier(record), throwsException);
    });
  });

  group('extractScope', () {
    test('returns profileId', () {
      final record = _makeRecord(profileId: 'profile-xyz');
      expect(adapter.extractScope(record), 'profile-xyz');
    });
  });

  group('extractUpdatedAt', () {
    test('returns updatedAt', () {
      final dt = DateTime(2025, 6, 1, 14, 30);
      final record = _makeRecord(updatedAt: dt);
      expect(adapter.extractUpdatedAt(record), dt);
    });

    test('defaults to createdAt when updatedAt not provided', () {
      final created = DateTime(2025, 1, 1);
      final record = CalorieRecord(
        id: 'r',
        value: 0,
        description: null,
        sortOrder: 0,
        eatenAt: null,
        createdAt: created,
        profileId: 'p',
        wakingPeriodId: null,
      );
      expect(adapter.extractUpdatedAt(record), created);
    });
  });

  test('toSyncPayload includes created_at_day', () {
    final record = _makeRecord();
    final json = adapter.toSyncPayload(record);
    expect(json.containsKey('created_at_day'), isTrue);
    expect(json['created_at_day'], isA<int>());
  });
}

CalorieRecord _makeRecord({
  String? id = 'rec-1',
  String profileId = 'profile-1',
  DateTime? updatedAt,
}) {
  final now = DateTime(2025, 3, 15);
  return CalorieRecord(
    id: id,
    value: 100,
    description: 'test',
    sortOrder: 0,
    eatenAt: null,
    createdAt: now,
    updatedAt: updatedAt,
    profileId: profileId,
    wakingPeriodId: null,
  );
}
