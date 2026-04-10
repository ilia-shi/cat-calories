import 'dart:convert';
import 'package:http/http.dart' as http;
import '../sync_transport.dart';
import 'config.dart';

final class RestSyncTransport implements SyncTransport {
  final String _baseUrl;
  final Future<String> Function() _getAccessToken;
  final Duration _timeout;
  final http.Client _client;

  RestSyncTransport({
    required String baseUrl,
    required Future<String> Function() getAccessToken,
    required Duration timeout,
    http.Client? client,
  })  : _baseUrl = baseUrl.endsWith('/')
            ? baseUrl.substring(0, baseUrl.length - 1)
            : baseUrl,
        _getAccessToken = getAccessToken,
        _timeout = timeout,
        _client = client ?? http.Client();

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

    final response = await _client
        .post(
          Uri.parse('$_baseUrl/api/v1/sync/push'),
          headers: headers,
          body: jsonEncode(body),
        )
        .timeout(_timeout);

    if (response.statusCode == 401) {
      throw const SyncAuthException('Token expired');
    }
    if (response.statusCode != 200) {
      throw SyncTransportException(
        'Push failed: ${response.statusCode}',
        statusCode: response.statusCode,
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return SyncResult(
      accepted: json['accepted'] as int,
      rejected: json['rejected'] as int? ?? 0,
      conflicts: (json['conflicts'] as List<dynamic>?)
              ?.map((c) => SyncConflict(
                    entityId: c['entity_id'] as String,
                    localVersion: SyncEntry.fromJson(
                        c['local'] as Map<String, dynamic>),
                    serverVersion: SyncEntry.fromJson(
                        c['server'] as Map<String, dynamic>),
                  ))
              .toList() ??
          [],
      serverTimestamp: json['server_timestamp'] as String?,
    );
  }

  // --- Pull ---

  @override
  Future<PullResult> pull({
    required String entityType,
    required String sinceHlc,
    int limit = 100,
  }) async {
    final headers = await _headers();

    final uri = Uri.parse('$_baseUrl/api/v1/sync/pull').replace(
      queryParameters: {
        'entity_type': entityType,
        'since': sinceHlc,
        'limit': limit.toString(),
      },
    );

    final response =
        await _client.get(uri, headers: headers).timeout(_timeout);

    if (response.statusCode == 401) {
      throw const SyncAuthException('Token expired');
    }
    if (response.statusCode != 200) {
      throw SyncTransportException(
        'Pull failed: ${response.statusCode}',
        statusCode: response.statusCode,
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return PullResult(
      entries: (json['entries'] as List<dynamic>)
          .map((e) => SyncEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      hasMore: json['has_more'] as bool? ?? false,
      serverTimestamp: json['server_timestamp'] as String?,
    );
  }

  // --- Health check ---

  @override
  Future<bool> healthCheck() async {
    try {
      final response = await _client
          .get(Uri.parse('$_baseUrl/health'))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) return false;
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return json['database'] == true;
    } catch (_) {
      return false;
    }
  }

  // --- REST does not support push notifications ---

  @override
  Stream<SyncEntry> get remoteChanges => const Stream.empty();

  @override
  Future<void> dispose() async {
    _client.close();
  }
}
