import 'dart:convert';
import 'package:cat_calories/features/sync/transport/transport_config.dart';
import 'package:cat_calories/features/sync/transport/rest/config.dart';

final class SyncServer {
  final String id;
  final String displayName;
  final TransportConfig transport;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastSeenAt;
  final int protocolVersion;
  final String serverUrl;
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
    required this.serverUrl,
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
      serverUrl: json['server_url'] ?? '',
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
        'server_url': serverUrl,
        'server_version': serverVersion,
        'auth_json': authConfig != null ? jsonEncode(authConfig) : null,
      };

  SyncServer copyWith({
    String? displayName,
    TransportConfig? transport,
    bool? isActive,
    DateTime? lastSeenAt,
    int? protocolVersion,
    String? serverUrl,
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
      serverUrl: serverUrl ?? this.serverUrl,
      serverVersion: serverVersion ?? this.serverVersion,
      authConfig: authConfig ?? this.authConfig,
    );
  }
}
