import 'dart:convert';
import 'package:sqlite3/sqlite3.dart';

class HlcGenerator {
  int _lastMicros = 0;
  int _counter = 0;

  /// Generate a monotonically increasing HLC timestamp.
  /// Format: "<unix_micros>-<counter>" (lexicographically sortable).
  String generate() {
    final now = DateTime.now().microsecondsSinceEpoch;
    if (now <= _lastMicros) {
      _counter++;
    } else {
      _lastMicros = now;
      _counter = 0;
    }
    return '$_lastMicros-$_counter';
  }
}

class SyncEntryRow {
  final String entityType;
  final String entityId;
  final String scope;
  final String userId;
  final String clientHlc;
  final String serverHlc;
  final int version;
  final bool isDeleted;
  final Map<String, dynamic>? payload;

  const SyncEntryRow({
    required this.entityType,
    required this.entityId,
    required this.scope,
    required this.userId,
    required this.clientHlc,
    required this.serverHlc,
    required this.version,
    required this.isDeleted,
    this.payload,
  });

  Map<String, dynamic> toJson() => {
        'entity_type': entityType,
        'entity_id': entityId,
        'scope': scope,
        'client_hlc': clientHlc,
        'server_hlc': serverHlc,
        'version': version,
        'is_deleted': isDeleted,
        'payload': payload,
      };
}

class SyncConflictInfo {
  final String entityId;
  final SyncEntryRow local;
  final SyncEntryRow server;

  const SyncConflictInfo({
    required this.entityId,
    required this.local,
    required this.server,
  });
}

class SyncEntryRepository {
  final Database _db;
  final HlcGenerator hlc;

  SyncEntryRepository(this._db, this.hlc);

  /// Check idempotency — returns accepted count if already processed, or null.
  int? checkIdempotency(String key, String userId) {
    final result = _db.select(
      'SELECT accepted FROM sync_idempotency WHERE idempotency_key = ? AND user_id = ?',
      [key, userId],
    );
    if (result.isEmpty) return null;
    return result.first['accepted'] as int;
  }

  void saveIdempotency(String key, String userId, int accepted) {
    _db.execute(
      'INSERT OR REPLACE INTO sync_idempotency (idempotency_key, user_id, accepted) VALUES (?, ?, ?)',
      [key, userId, accepted],
    );
  }

  /// Upsert a sync entry. Returns (accepted, conflict).
  /// If the incoming version <= existing version, it's a conflict.
  (bool accepted, SyncEntryRow? existingEntry) upsert({
    required String entityType,
    required String entityId,
    required String scope,
    required String userId,
    required String clientHlc,
    required int version,
    required bool isDeleted,
    required Map<String, dynamic>? payload,
  }) {
    // Check existing
    final existing = _db.select(
      'SELECT * FROM sync_entries WHERE entity_type = ? AND entity_id = ?',
      [entityType, entityId],
    );

    if (existing.isNotEmpty) {
      final row = existing.first;
      final existingVersion = row['version'] as int;
      if (version <= existingVersion) {
        // Conflict — incoming version not newer
        return (false, _rowToEntry(row));
      }
    }

    final serverHlc = hlc.generate();
    _db.execute('''
      INSERT OR REPLACE INTO sync_entries
        (entity_type, entity_id, scope, user_id, client_hlc, server_hlc, version, is_deleted, payload)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''', [
      entityType,
      entityId,
      scope,
      userId,
      clientHlc,
      serverHlc,
      version,
      isDeleted ? 1 : 0,
      payload != null ? jsonEncode(payload) : null,
    ]);

    return (true, null);
  }

  /// Pull entries since a given HLC for a specific user and entity type.
  List<SyncEntryRow> findSince({
    required String userId,
    required String entityType,
    required String sinceHlc,
    int limit = 100,
  }) {
    final result = _db.select(
      'SELECT * FROM sync_entries WHERE user_id = ? AND entity_type = ? AND server_hlc > ? ORDER BY server_hlc ASC LIMIT ?',
      [userId, entityType, sinceHlc, limit + 1],
    );
    return result.take(limit).map(_rowToEntry).toList();
  }

  /// Check if there are more entries beyond the limit.
  bool hasMore({
    required String userId,
    required String entityType,
    required String sinceHlc,
    required int limit,
  }) {
    final result = _db.select(
      'SELECT COUNT(*) as cnt FROM sync_entries WHERE user_id = ? AND entity_type = ? AND server_hlc > ?',
      [userId, entityType, sinceHlc],
    );
    final count = result.first['cnt'] as int;
    return count > limit;
  }

  SyncEntryRow _rowToEntry(Row row) {
    final payloadStr = row['payload'] as String?;
    return SyncEntryRow(
      entityType: row['entity_type'] as String,
      entityId: row['entity_id'] as String,
      scope: row['scope'] as String,
      userId: row['user_id'] as String,
      clientHlc: row['client_hlc'] as String,
      serverHlc: row['server_hlc'] as String,
      version: row['version'] as int,
      isDeleted: (row['is_deleted'] as int) == 1,
      payload: payloadStr != null
          ? jsonDecode(payloadStr) as Map<String, dynamic>
          : null,
    );
  }
}
