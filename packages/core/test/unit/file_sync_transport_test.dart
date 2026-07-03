import 'dart:convert';
import 'dart:io';

import 'package:cat_calories_core/features/sync/transport/file/device_identity.dart';
import 'package:cat_calories_core/features/sync/transport/file/file_cursor_store.dart';
import 'package:cat_calories_core/features/sync/transport/file/file_sync_transport.dart';
import 'package:cat_calories_core/features/sync/transport/file/ndjson_log.dart';
import 'package:cat_calories_core/features/sync/transport/sync_transport.dart';
import 'package:test/test.dart';

void main() {
  late Directory temp;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('file_sync_test_');
  });

  tearDown(() async {
    await temp.delete(recursive: true);
  });

  SyncEntry entry(String id, {int version = 1, String hlc = '100-0'}) =>
      SyncEntry(
        entityId: id,
        version: version,
        hlc: hlc,
        isDeleted: false,
        payload: {'id': id, 'value': 42},
      );

  FileSyncTransport transport(String deviceId, {FileCursorStore? cursors}) =>
      FileSyncTransport(
        root: temp,
        deviceId: deviceId,
        cursors: cursors ?? InMemoryCursorStore(),
      );

  SyncBatch batch(List<SyncEntry> entries) => SyncBatch(
        idempotencyKey: 'k',
        entityType: 'calorie_item',
        entries: entries,
      );

  group('NdjsonLog', () {
    test('append/read round-trip with byte cursor', () async {
      final file = File('${temp.path}/log.ndjson');
      await NdjsonLog.append(file, [
        {'a': 1},
        {'b': 2},
      ]);

      final first = await NdjsonLog.read(file, fromOffset: 0, maxLines: 1);
      expect(first.lines, [
        {'a': 1}
      ]);
      expect(first.hasMore, isTrue);

      final second = await NdjsonLog.read(file,
          fromOffset: first.endOffset, maxLines: 10);
      expect(second.lines, [
        {'b': 2}
      ]);
      expect(second.hasMore, isFalse);

      final third = await NdjsonLog.read(file,
          fromOffset: second.endOffset, maxLines: 10);
      expect(third.lines, isEmpty);
    });

    test('torn trailing line is left unconsumed, then read once completed',
        () async {
      final file = File('${temp.path}/log.ndjson');
      await file.writeAsString('{"a": 1}\n{"torn": ');

      final result = await NdjsonLog.read(file, fromOffset: 0, maxLines: 10);
      expect(result.lines, [
        {'a': 1}
      ]);
      expect(result.hasMore, isFalse);

      await file.writeAsString('{"a": 1}\n{"torn": 2}\n');
      final retry = await NdjsonLog.read(file,
          fromOffset: result.endOffset, maxLines: 10);
      expect(retry.lines, [
        {'torn': 2}
      ]);
    });

    test('malformed interior line is skipped but consumed', () async {
      final file = File('${temp.path}/log.ndjson');
      await file.writeAsString('not json\n{"ok": 1}\n');

      final result = await NdjsonLog.read(file, fromOffset: 0, maxLines: 10);
      expect(result.lines, [
        {'ok': 1}
      ]);
      expect(result.hasMore, isFalse);
    });
  });

  group('FileSyncTransport', () {
    test('push appends self-describing lines to own log only', () async {
      final a = transport('device-a');
      final result = await a.push(batch([entry('r1'), entry('r2')]));

      expect(result.accepted, 2);
      final log =
          File('${temp.path}/v1/logs/device-a/calorie_item.ndjson');
      final lines = await log.readAsLines();
      expect(lines, hasLength(2));
      final decoded = jsonDecode(lines.first) as Map<String, dynamic>;
      expect(decoded['entity_id'], 'r1');
      expect(decoded['entity_type'], 'calorie_item');
      expect(decoded['device_id'], 'device-a');
    });

    test('pull sees other devices, never itself; cursor advances', () async {
      final a = transport('device-a');
      final b = transport('device-b');
      await a.push(batch([entry('r1', hlc: '100-0')]));
      await b.push(batch([entry('r2', hlc: '200-0')]));

      final pulledByB = await b.pull(
          entityType: 'calorie_item', sinceHlc: '', limit: 100);
      expect(pulledByB.entries.map((e) => e.entityId), ['r1']);
      expect(pulledByB.serverTimestamp, '100-0');

      final again = await b.pull(
          entityType: 'calorie_item', sinceHlc: '', limit: 100);
      expect(again.entries, isEmpty);

      await a.push(batch([entry('r3', hlc: '300-0')]));
      final incremental = await b.pull(
          entityType: 'calorie_item', sinceHlc: '', limit: 100);
      expect(incremental.entries.map((e) => e.entityId), ['r3']);
    });

    test('limit truncation pages with hasMore until drained', () async {
      final a = transport('device-a');
      final b = transport('device-b');
      await a.push(batch([entry('r1'), entry('r2'), entry('r3')]));

      final page1 =
          await b.pull(entityType: 'calorie_item', sinceHlc: '', limit: 2);
      expect(page1.entries, hasLength(2));
      expect(page1.hasMore, isTrue);

      final page2 =
          await b.pull(entityType: 'calorie_item', sinceHlc: '', limit: 2);
      expect(page2.entries.map((e) => e.entityId), ['r3']);
      expect(page2.hasMore, isFalse);
    });

    test('cursor survives a transport restart via JsonFileCursorStore',
        () async {
      final cursorFile = File('${temp.path}/local/cursors.json');
      final a = transport('device-a');
      await a.push(batch([entry('r1')]));

      final b1 =
          transport('device-b', cursors: JsonFileCursorStore(cursorFile));
      final first =
          await b1.pull(entityType: 'calorie_item', sinceHlc: '', limit: 100);
      expect(first.entries, hasLength(1));

      // Fresh instance, same cursor file — nothing is re-read.
      final b2 =
          transport('device-b', cursors: JsonFileCursorStore(cursorFile));
      final second =
          await b2.pull(entityType: 'calorie_item', sinceHlc: '', limit: 100);
      expect(second.entries, isEmpty);
    });

    test('sync-conflict log copies are merged like any other log', () async {
      final b = transport('device-b');
      final conflict = File(
          '${temp.path}/v1/logs/device-a/calorie_item.sync-conflict-20260703.ndjson');
      await NdjsonLog.append(conflict, [entry('rc').toJson()]);

      final pulled =
          await b.pull(entityType: 'calorie_item', sinceHlc: '', limit: 100);
      expect(pulled.entries.map((e) => e.entityId), ['rc']);
    });

    test('pull only reads the requested entity type', () async {
      final a = transport('device-a');
      final b = transport('device-b');
      await a.push(SyncBatch(
          idempotencyKey: 'k', entityType: 'meal', entries: [entry('m1')]));
      await a.push(batch([entry('r1')]));

      final meals =
          await b.pull(entityType: 'meal', sinceHlc: '', limit: 100);
      expect(meals.entries.map((e) => e.entityId), ['m1']);
    });

    test('two devices converge regardless of delivery order', () async {
      final a = transport('device-a');
      final b = transport('device-b');

      // Concurrent edits of the same entity from both devices.
      await a.push(batch([entry('shared', version: 2, hlc: '200-0')]));
      await b.push(batch([entry('shared', version: 1, hlc: '100-0')]));
      await a.push(batch([entry('only-a', hlc: '150-0')]));
      await b.push(batch([entry('only-b', hlc: '160-0')]));

      final seenByA =
          await a.pull(entityType: 'calorie_item', sinceHlc: '', limit: 100);
      final seenByB =
          await b.pull(entityType: 'calorie_item', sinceHlc: '', limit: 100);

      // Each side sees exactly the other's entries; the LWW upsert
      // (version-then-hlc, exercised in the engine) picks the same winner
      // for 'shared' on both sides.
      expect(seenByA.entries.map((e) => e.entityId).toSet(),
          {'shared', 'only-b'});
      expect(seenByB.entries.map((e) => e.entityId).toSet(),
          {'shared', 'only-a'});
      final sharedForB =
          seenByB.entries.firstWhere((e) => e.entityId == 'shared');
      expect(sharedForB.version, 2);
    });

    test('healthCheck true on writable root, false otherwise', () async {
      expect(await transport('device-a').healthCheck(), isTrue);

      final missing = FileSyncTransport(
        root: Directory('/nonexistent-root-for-sure'),
        deviceId: 'device-a',
        cursors: InMemoryCursorStore(),
      );
      expect(await missing.healthCheck(), isFalse);
    });
  });

  group('DeviceIdentity', () {
    test('stable across calls and writes synced meta', () async {
      final local = File('${temp.path}/local/device_id');
      final id1 = await DeviceIdentity.ensure(
          localFile: local, syncRoot: temp, displayName: 'phone');
      final id2 =
          await DeviceIdentity.ensure(localFile: local, syncRoot: temp);

      expect(id1, id2);
      final meta = File('${temp.path}/v1/meta/device-$id1.json');
      expect(await meta.exists(), isTrue);
      final decoded = jsonDecode(await meta.readAsString());
      expect(decoded['device_id'], id1);
      expect(decoded['display_name'], 'phone');
    });
  });
}
