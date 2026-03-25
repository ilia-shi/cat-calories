final class EntityVersion {
  final String entityId;
  final String entityType;
  final int version;
  final String hlcTimestamp;
  final bool isDeleted;
  final DateTime updatedAt;

  const EntityVersion({
    required this.entityId,
    required this.entityType,
    this.version = 1,
    required this.hlcTimestamp,
    this.isDeleted = false,
    required this.updatedAt,
  });

  EntityVersion bump(String newHlc) => EntityVersion(
    entityId: entityId,
    entityType: entityType,
    version: version + 1,
    hlcTimestamp: newHlc,
    isDeleted: isDeleted,
    updatedAt: DateTime.now(),
  );

  EntityVersion softDelete(String newHlc) => EntityVersion(
    entityId: entityId,
    entityType: entityType,
    version: version + 1,
    hlcTimestamp: newHlc,
    isDeleted: true,
    updatedAt: DateTime.now(),
  );
}