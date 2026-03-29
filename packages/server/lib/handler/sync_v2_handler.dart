import 'dart:io';
import 'package:cat_calories_core/http/controller.dart';
import 'package:cat_calories_core/http/router.dart';
import '../auth/auth_middleware.dart';
import '../data/sqlite/sync_entry_repository.dart';

class SyncV2Handler extends Controller {
  final SyncEntryRepository syncEntries;
  final UserExtractor userExtractor;

  SyncV2Handler({required this.syncEntries, required this.userExtractor});

  @override
  void register(Router router) {
    router.post('/api/v1/sync/push', _push);
    router.get('/api/v1/sync/pull', _pull);
  }

  Future<void> _push(HttpRequest request, Map<String, String> params) async {
    final userId = await requireAuth(request, userExtractor);
    if (userId == null) return;

    final data = await parseJsonBody(request);
    final idempotencyKey = data['idempotency_key'] as String? ?? '';
    final entityType = data['entity_type'] as String? ?? '';
    final entries = data['entries'] as List<dynamic>? ?? [];

    // Idempotency check
    if (idempotencyKey.isNotEmpty) {
      final previous = syncEntries.checkIdempotency(idempotencyKey, userId);
      if (previous != null) {
        respondJson(request, HttpStatus.ok, {
          'accepted': previous,
          'rejected': 0,
          'conflicts': <dynamic>[],
          'server_timestamp': syncEntries.hlc.generate(),
        });
        return;
      }
    }

    int accepted = 0;
    final conflicts = <Map<String, dynamic>>[];

    for (final entry in entries) {
      final e = entry as Map<String, dynamic>;
      final entityId = e['entity_id'] as String;
      final version = e['version'] as int;
      final hlc = e['hlc'] as String? ?? '';
      final isDeleted = e['is_deleted'] as bool? ?? false;
      final payload = e['payload'] as Map<String, dynamic>?;

      final (ok, existing) = syncEntries.upsert(
        entityType: entityType,
        entityId: entityId,
        scope: e['scope'] as String? ?? '',
        userId: userId,
        clientHlc: hlc,
        version: version,
        isDeleted: isDeleted,
        payload: payload,
      );

      if (ok) {
        accepted++;
      } else if (existing != null) {
        conflicts.add({
          'entity_id': entityId,
          'local': {
            'entity_id': entityId,
            'version': version,
            'hlc': hlc,
            'is_deleted': isDeleted,
            'payload': payload,
          },
          'server': existing.toJson(),
        });
      }
    }

    // Save idempotency
    if (idempotencyKey.isNotEmpty) {
      syncEntries.saveIdempotency(idempotencyKey, userId, accepted);
    }

    respondJson(request, HttpStatus.ok, {
      'accepted': accepted,
      'rejected': conflicts.length,
      'conflicts': conflicts,
      'server_timestamp': syncEntries.hlc.generate(),
    });
  }

  Future<void> _pull(HttpRequest request, Map<String, String> params) async {
    final userId = await requireAuth(request, userExtractor);
    if (userId == null) return;

    final queryParams = request.uri.queryParameters;
    final entityType = queryParams['entity_type'] ?? '';
    final sinceHlc = queryParams['since'] ?? '';
    var limit = int.tryParse(queryParams['limit'] ?? '') ?? 100;
    if (limit > 1000) limit = 1000;

    final entries = syncEntries.findSince(
      userId: userId,
      entityType: entityType,
      sinceHlc: sinceHlc,
      limit: limit,
    );

    final hasMore = entries.length == limit &&
        syncEntries.hasMore(
          userId: userId,
          entityType: entityType,
          sinceHlc: sinceHlc,
          limit: limit,
        );

    respondJson(request, HttpStatus.ok, {
      'entries': entries.map((e) => e.toJson()).toList(),
      'has_more': hasMore,
      'server_timestamp': syncEntries.hlc.generate(),
    });
  }
}
