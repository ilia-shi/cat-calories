final class ReplicaState {
  final String entityId;
  final String entityType;
  final String serverId;
  final int lastPushedVersion;
  final DateTime? lastPushedAt;
  final int lastPulledVersion;
  final DateTime? lastPulledAt;
  final ReplicaStatus status;

  const ReplicaState({
    required this.entityId,
    required this.entityType,
    required this.serverId,
    this.lastPushedVersion = 0,
    this.lastPushedAt,
    this.lastPulledVersion = 0,
    this.lastPulledAt,
    this.status = ReplicaStatus.pending,
  });

  bool needsPush(int currentEntityVersion) =>
      currentEntityVersion > lastPushedVersion;

  ReplicaState markPushed(int version) => ReplicaState(
        entityId: entityId,
        entityType: entityType,
        serverId: serverId,
        lastPushedVersion: version,
        lastPushedAt: DateTime.now(),
        lastPulledVersion: lastPulledVersion,
        lastPulledAt: lastPulledAt,
        status: ReplicaStatus.synced,
      );

  ReplicaState markPulled(int version) => ReplicaState(
        entityId: entityId,
        entityType: entityType,
        serverId: serverId,
        lastPushedVersion: lastPushedVersion,
        lastPushedAt: lastPushedAt,
        lastPulledVersion: version,
        lastPulledAt: DateTime.now(),
        status: ReplicaStatus.synced,
      );

  ReplicaState markFailed(String? error) => ReplicaState(
        entityId: entityId,
        entityType: entityType,
        serverId: serverId,
        lastPushedVersion: lastPushedVersion,
        lastPushedAt: lastPushedAt,
        lastPulledVersion: lastPulledVersion,
        lastPulledAt: lastPulledAt,
        status: ReplicaStatus.error,
      );
}

enum ReplicaStatus {
  pending,
  synced,
  modified,
  error,
  conflict,
}
