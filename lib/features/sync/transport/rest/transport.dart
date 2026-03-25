import '../sync_transport.dart';
import 'config.dart';

final class RestSyncTransport implements SyncTransport {
  final String _baseUrl;
  final Future<String> Function() _getAccessToken;
  final Duration _timeout;

  RestSyncTransport({
    required String baseUrl,
    required Future<String> Function() getAccessToken,
    required Duration timeout,
  })  : _baseUrl = baseUrl.endsWith('/')
            ? baseUrl.substring(0, baseUrl.length - 1)
            : baseUrl,
        _getAccessToken = getAccessToken,
        _timeout = timeout;

  Future<Map<String, String>> _headers() async {
    final token = await _getAccessToken();

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  factory RestSyncTransport.fromConfig(RestTransportConfig config) {
    return RestSyncTransport(
        baseUrl: config.baseUrl,
        timeout: config.timeout,
        getAccessToken: () {
          return Future.value('TODO');
        });
  }

  @override
  Future<SyncResult> push(SyncBatch batch) async {
    final headers = await _headers();

    final body = {
      'idempotency_key': batch.idempotencyKey,
      'entity_type': batch.entityType,
      'entries': batch.entries.map((e) => e.toJson()).toList(),
    };

    // final response = await _client
    //     .post(
    //       Uri.parse('$_baseUrl/api/v1/sync/push'),
    //       headers: headers,
    //       body: jsonEncode(body),
    //     )
    //     .timeout(_timeout);
    //
    // if (response.statusCode == 401) {
    //   throw SyncAuthException('Token expired');
    // }
    // if (response.statusCode != 200) {
    //   throw SyncTransportException(
    //     'Push failed: ${response.statusCode}',
    //     statusCode: response.statusCode,
    //   );
    // }
    //
    // final json = jsonDecode(response.body) as Map<String, dynamic>;
    // return SyncResult(
    //   accepted: json['accepted'] as int,
    //   rejected: json['rejected'] as int? ?? 0,
    //   conflicts: (json['conflicts'] as List<dynamic>?)
    //       ?.map((c) => SyncConflict(
    //             entityId: c['entity_id'],
    //             localVersion: SyncEntry.fromJson(c['local']),
    //             serverVersion: SyncEntry.fromJson(c['server']),
    //           ))
    //       .toList() ?? [],
    //   serverTimestamp: json['server_timestamp'] as String?,
    // );

    // Заглушка для компиляции:
    return SyncResult(accepted: batch.entries.length);
  }

  // --- Pull ---

  @override
  Future<PullResult> pull({
    required String entityType,
    required String sinceHlc,
    int limit = 100,
  }) async {
    final headers = await _headers();

    final queryParams = {
      'entity_type': entityType,
      'since': sinceHlc,
      'limit': limit.toString(),
    };

    // final uri = Uri.parse('$_baseUrl/api/v1/sync/pull')
    //     .replace(queryParameters: queryParams);
    //
    // final response = await _client
    //     .get(uri, headers: headers)
    //     .timeout(_timeout);
    //
    // if (response.statusCode == 401) {
    //   throw SyncAuthException('Token expired');
    // }
    // if (response.statusCode != 200) {
    //   throw SyncTransportException(
    //     'Pull failed: ${response.statusCode}',
    //     statusCode: response.statusCode,
    //   );
    // }
    //
    // final json = jsonDecode(response.body) as Map<String, dynamic>;
    // return PullResult(
    //   entries: (json['entries'] as List<dynamic>)
    //       .map((e) => SyncEntry.fromJson(e as Map<String, dynamic>))
    //       .toList(),
    //   hasMore: json['has_more'] as bool? ?? false,
    //   serverTimestamp: json['server_timestamp'] as String?,
    // );

    // Заглушка:
    return const PullResult(entries: []);
  }

  // --- Health check ---

  @override
  Future<bool> healthCheck() async {
    try {
      // final response = await _client
      //     .get(Uri.parse('$_baseUrl/api/v1/health'))
      //     .timeout(const Duration(seconds: 5));
      // return response.statusCode == 200;
      return true;
    } catch (_) {
      return false;
    }
  }

  // --- REST не поддерживает push-уведомления ---

  @override
  Stream<SyncEntry> get remoteChanges => const Stream.empty();

  @override
  Future<void> dispose() async {
    // _client.close();
  }
}
