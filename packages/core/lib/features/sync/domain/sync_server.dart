import 'dart:convert';
import 'package:cat_calories_core/features/sync/transport/transport_config.dart';
import 'package:cat_calories_core/features/sync/transport/rest/config.dart';

final class SyncServer {
  final String id;
  final String displayName;
  final TransportConfig transport;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastSeenAt;
  final int protocolVersion;
  final List<String> serverUrls;
  final String? serverVersion;
  final Map<String, dynamic>? authConfig;

  const SyncServer({
    required this.id,
    required this.displayName,
    required this.transport,
    this.isActive = true,
    required this.createdAt,
    this.lastSeenAt,
    this.protocolVersion = 1,
    required this.serverUrls,
    this.serverVersion,
    this.authConfig,
  });

  factory SyncServer.fromJson(Map<String, dynamic> json) {
    final transportJson = json['transport_json'] is String
        ? jsonDecode(json['transport_json']) as Map<String, dynamic>
        : json['transport_json'] as Map<String, dynamic>;

    TransportConfig transport;
    if (transportJson['type'] == 'rest') {
      transport = RestTransportConfig.fromJson(transportJson);
    } else {
      transport = RestTransportConfig(baseUrl: transportJson['base_url'] ?? '');
    }

    Map<String, dynamic>? authConfig;
    if (json['auth_json'] != null) {
      authConfig = json['auth_json'] is String
          ? jsonDecode(json['auth_json']) as Map<String, dynamic>
          : json['auth_json'] as Map<String, dynamic>;
    }

    return SyncServer(
      id: json['id'],
      displayName: json['display_name'],
      transport: transport,
      isActive: json['is_active'] == 1 || json['is_active'] == true,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['created_at']),
      lastSeenAt: json['last_seen_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['last_seen_at'])
          : null,
      protocolVersion: json['protocol_version'] ?? 1,
      serverUrls: _parseServerUrls(json),
      serverVersion: json['server_version'],
      authConfig: authConfig,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'display_name': displayName,
        'transport_type': transport.type,
        'transport_json': jsonEncode(transport.toJson()),
        'is_active': isActive ? 1 : 0,
        'created_at': createdAt.millisecondsSinceEpoch,
        'last_seen_at': lastSeenAt?.millisecondsSinceEpoch,
        'protocol_version': protocolVersion,
        'server_urls': jsonEncode(serverUrls),
        'server_version': serverVersion,
        'auth_json': authConfig != null ? jsonEncode(authConfig) : null,
      };

  SyncServer copyWith({
    String? displayName,
    TransportConfig? transport,
    bool? isActive,
    DateTime? lastSeenAt,
    int? protocolVersion,
    List<String>? serverUrls,
    String? serverVersion,
    Map<String, dynamic>? authConfig,
  }) {
    return SyncServer(
      id: id,
      displayName: displayName ?? this.displayName,
      transport: transport ?? this.transport,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      protocolVersion: protocolVersion ?? this.protocolVersion,
      serverUrls: serverUrls ?? this.serverUrls,
      serverVersion: serverVersion ?? this.serverVersion,
      authConfig: authConfig ?? this.authConfig,
    );
  }

  static List<String> _parseServerUrls(Map<String, dynamic> json) {
    // New format: server_urls as JSON array
    if (json['server_urls'] != null) {
      final raw = json['server_urls'];
      final list = raw is String ? jsonDecode(raw) as List : raw as List;
      return list.cast<String>();
    }
    // Legacy format: single server_url
    final url = json['server_url'] as String?;
    return url != null && url.isNotEmpty ? [url] : [];
  }
}
