abstract class SyncAdapter<T> {
  String get entityType;

  Map<String, dynamic> toSyncPayload(T entity);

  T fromSyncPayload(Map<String, dynamic> json);

  String extractIdentifier(T entity);

  String extractScope(T entity);

  DateTime extractUpdatedAt(T entity);

  ConflictStrategy get conflictStrategy => ConflictStrategy.fieldLevelLww;
}

/// Repository interface for entities that participate in sync.
/// Each syncable entity type provides an implementation.
abstract class SyncEntityRepository<T> {
  Future<List<T>> findAllByScopes(Set<String> scopes);
  Future<T?> findById(String id);
  Future<void> upsert(T entity);
  Future<void> deleteById(String id);
}

enum ConflictStrategy {
  fieldLevelLww,
  entityLevelLww,
  customMerge,
}

final class SyncAdapterRegistry {
  final Map<String, _SyncRegistration> _registrations = {};

  void register<T>(SyncAdapter<T> adapter, SyncEntityRepository<T> repository) {
    _registrations[adapter.entityType] = _SyncRegistration<T>(adapter, repository);
  }

  SyncAdapter<T> getAdapter<T>(String type) {
    final reg = _registrations[type];
    if (reg == null) throw StateError('No adapter for $type');
    return reg.adapter as SyncAdapter<T>;
  }

  SyncEntityRepository<T> getRepository<T>(String type) {
    final reg = _registrations[type];
    if (reg == null) throw StateError('No repository for $type');
    return reg.repository as SyncEntityRepository<T>;
  }

  List<String> get registeredTypes => _registrations.keys.toList();

  /// Run a callback with the typed adapter+repository pair for each entity type.
  Future<void> forEach(
    Future<void> Function<T>(SyncAdapter<T> adapter, SyncEntityRepository<T> repo) fn,
  ) async {
    for (final reg in _registrations.values) {
      await reg.applyTyped(fn);
    }
  }
}

final class _SyncRegistration<T> {
  final SyncAdapter<T> adapter;
  final SyncEntityRepository<T> repository;

  _SyncRegistration(this.adapter, this.repository);

  Future<void> applyTyped(
    Future<void> Function<U>(SyncAdapter<U> adapter, SyncEntityRepository<U> repo) fn,
  ) => fn<T>(adapter, repository);
}
