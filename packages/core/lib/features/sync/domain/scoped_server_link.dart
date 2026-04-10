final class ScopedServerLink {
  final String id;
  final String scope;
  final String serverId;
  final bool syncEnabled;
  final DateTime linkedAt;

  const ScopedServerLink({
    required this.id,
    required this.scope,
    required this.serverId,
    this.syncEnabled = true,
    required this.linkedAt,
  });

  factory ScopedServerLink.fromJson(Map<String, dynamic> json) =>
      ScopedServerLink(
        id: json['id'],
        scope: json['scope'],
        serverId: json['server_id'],
        syncEnabled: json['sync_enabled'] == 1 || json['sync_enabled'] == true,
        linkedAt: DateTime.fromMillisecondsSinceEpoch(json['linked_at']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'scope': scope,
        'server_id': serverId,
        'sync_enabled': syncEnabled ? 1 : 0,
        'linked_at': linkedAt.millisecondsSinceEpoch,
      };
}
