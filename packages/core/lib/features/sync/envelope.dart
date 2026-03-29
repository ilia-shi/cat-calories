import 'package:cat_calories_core/features/sync/replica.dart';

import 'entity_version.dart';

final class Envelope<T> {
  final T entity;
  final EntityVersion version;
  final Map<String, ReplicaState> replicas; // serverId → ReplicaState

  const Envelope({
    required this.entity,
    required this.version,
    this.replicas = const {},
  });

  List<String> serversPendingPush() => replicas.entries
      .where((e) => e.value.needsPush(version.version))
      .map((e) => e.key)
      .toList();
}
