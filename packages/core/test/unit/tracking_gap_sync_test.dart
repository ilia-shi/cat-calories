import 'dart:io';

import 'package:cat_calories_core/features/calorie_tracking/domain/tracking_gap.dart';
import 'package:cat_calories_core/features/calorie_tracking/sync/tracking_gap_sync_adapter.dart';
import 'package:cat_calories_core/features/sync/transport/file/file_cursor_store.dart';
import 'package:cat_calories_core/features/sync/transport/file/file_sync_transport.dart';
import 'package:cat_calories_core/features/sync/transport/sync_transport.dart';
import 'package:test/test.dart';

void main() {
  late Directory temp;
  final adapter = TrackingGapSyncAdapter();

  setUp(() {
    temp = Directory.systemTemp.createTempSync('tracking_gap_sync');
  });

  tearDown(() {
    temp.deleteSync(recursive: true);
  });

  FileSyncTransport device(String id) => FileSyncTransport(
        root: temp,
        deviceId: id,
        cursors: InMemoryCursorStore(),
      );

  SyncBatch batch(String key, TrackingGap gap) => SyncBatch(
        idempotencyKey: key,
        entityType: adapter.entityType,
        entries: [
          SyncEntry(
            entityId: adapter.extractIdentifier(gap),
            version: 1,
            hlc: adapter.extractUpdatedAt(gap).toUtc().toIso8601String(),
            isDeleted: false,
            payload: adapter.toSyncPayload(gap),
          ),
        ],
      );

  test('a soft delete reaches another device as an ordinary edit', () async {
    final created = DateTime(2026, 10, 10, 9);
    final deleted = DateTime(2026, 10, 10, 10);
    TrackingGap gap({DateTime? deletedAt}) => TrackingGap(
          id: 'g1',
          profileId: 'p1',
          startedAt: DateTime(2026, 10, 9),
          endedAt: DateTime(2026, 10, 10),
          description: null,
          createdAt: created,
          updatedAt: deletedAt ?? created,
          deletedAt: deletedAt,
        );

    final phone = device('phone');
    final tablet = device('tablet');
    await phone.push(batch('k1', gap()));
    await phone.push(batch('k2', gap(deletedAt: deleted)));

    final pulled = await tablet.pull(
      entityType: adapter.entityType,
      sinceHlc: '',
      limit: 100,
    );

    expect(pulled.entries, isNotEmpty);
    expect(pulled.entries.every((entry) => !entry.isDeleted), isTrue);
    final latest = adapter.fromSyncPayload(pulled.entries.last.payload!);
    expect(latest.isDeleted, isTrue);
    expect(adapter.extractUpdatedAt(latest), deleted);
  });
}
