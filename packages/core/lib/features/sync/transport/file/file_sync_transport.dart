import 'dart:io';

import '../sync_transport.dart';
import './file_cursor_store.dart';
import './ndjson_log.dart';

/// SyncTransport over a synced folder (Syncthing, cloud drive): the folder
/// replaces the server's role as a dumb relay of self-contained sync entries.
///
/// Storage is one append-only NDJSON log per (device, entity_type) under
/// `<root>/v1/logs/<deviceId>/<entityType>.ndjson`. Each device only ever
/// appends to its own files, so the folder-sync tool never has to merge a
/// file and never produces a real conflict. Merge semantics stay entirely in
/// the engine's version-then-HLC LWW upsert, which is idempotent — so
/// re-reads, duplicate pushes and even `.sync-conflict` copies are harmless.
///
/// `pull` deliberately ignores the engine's `sinceHlc` watermark: file
/// delivery is out of order (an offline device's log can arrive *after*
/// its hlc range was passed), so a single scalar anchor would skip entries
/// forever. Progress is tracked per source file in a local [FileCursorStore].
final class FileSyncTransport implements SyncTransport {
  final Directory root;
  final String deviceId;
  final FileCursorStore cursors;

  FileSyncTransport({
    required this.root,
    required this.deviceId,
    required this.cursors,
  });

  Directory get _logsDir => Directory('${root.path}/v1/logs');

  File _ownLog(String entityType) =>
      File('${_logsDir.path}/$deviceId/$entityType.ndjson');

  @override
  Future<SyncResult> push(SyncBatch batch) async {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    await NdjsonLog.append(
      _ownLog(batch.entityType),
      [
        for (final entry in batch.entries)
          {
            ...entry.toJson(),
            // Redundant with the path, but keeps every line self-describing
            // for LLM analysis and manual recovery.
            'entity_type': batch.entityType,
            'device_id': deviceId,
            'op_ts': now,
          },
      ],
    );
    return SyncResult(accepted: batch.entries.length);
  }

  @override
  Future<PullResult> pull({
    required String entityType,
    required String sinceHlc,
    required int limit,
  }) async {
    final entries = <SyncEntry>[];
    var hasMore = false;
    String? maxHlc;

    for (final file in await _otherDeviceLogs(entityType)) {
      if (entries.length >= limit) {
        hasMore = true;
        break;
      }
      final key = _cursorKey(file);
      final result = await NdjsonLog.read(
        file,
        fromOffset: await cursors.getOffset(key),
        maxLines: limit - entries.length,
      );
      for (final line in result.lines) {
        try {
          final entry = SyncEntry.fromJson(line);
          entries.add(entry);
          if (maxHlc == null || entry.hlc.compareTo(maxHlc) > 0) {
            maxHlc = entry.hlc;
          }
        } catch (_) {
          // A line that isn't a valid entry is consumed and forgotten.
        }
      }
      await cursors.setOffset(key, result.endOffset);
      if (result.hasMore) {
        hasMore = true;
      }
    }

    return PullResult(
      entries: entries,
      hasMore: hasMore,
      serverTimestamp: maxHlc,
    );
  }

  /// Every other device's logs for [entityType] — including Syncthing
  /// `.sync-conflict-*` copies: with single-writer files they shouldn't
  /// exist, but if one ever does it is itself a valid append-only log and
  /// merging it is harmless.
  Future<List<File>> _otherDeviceLogs(String entityType) async {
    if (!await _logsDir.exists()) {
      return const [];
    }
    final files = <File>[];
    await for (final deviceDir in _logsDir.list()) {
      if (deviceDir is! Directory) {
        continue;
      }
      final dirName = deviceDir.uri.pathSegments
          .lastWhere((segment) => segment.isNotEmpty);
      if (dirName == deviceId) {
        continue;
      }
      await for (final file in deviceDir.list()) {
        if (file is! File) {
          continue;
        }
        final name = file.uri.pathSegments.last;
        if (name.startsWith(entityType) && name.endsWith('.ndjson')) {
          files.add(file);
        }
      }
    }
    // Stable order so limit-truncated pulls resume deterministically.
    files.sort((a, b) => a.path.compareTo(b.path));
    return files;
  }

  String _cursorKey(File file) {
    final segments = file.uri.pathSegments;
    return '${segments[segments.length - 2]}/${segments.last}';
  }

  @override
  Future<bool> healthCheck() async {
    try {
      final probe = File('${root.path}/v1/.write_test_$deviceId');
      await probe.parent.create(recursive: true);
      await probe.writeAsString('ok', flush: true);
      await probe.delete();
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Stream<SyncEntry> get remoteChanges => const Stream.empty();

  @override
  Future<void> dispose() async {}
}
