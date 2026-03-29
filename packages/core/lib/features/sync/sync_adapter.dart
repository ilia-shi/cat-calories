abstract class SyncAdapter<T> {
  String get entityType;

  Map<String, dynamic> toSyncPayload(T entity);

  T fromSyncPayload(Map<String, dynamic> json);

  String extractIdentifier(T entity);

  String extractScope(T entity);

  ConflictStrategy get conflictStrategy => ConflictStrategy.fieldLevelLww;
}

enum ConflictStrategy {
  fieldLevelLww,
  entityLevelLww,
  customMerge,
}

final class SyncAdapterRegistry {
  final Map<String, SyncAdapter> _adapters = {};

  void register<T>(SyncAdapter<T> adapter) {
    _adapters[adapter.entityType] = adapter;
  }

  SyncAdapter<T> get<T>(String type) {
    final adapter = _adapters[type];
    if (adapter == null) {
      throw StateError('No adapter for $type');
    }

    return adapter as SyncAdapter<T>;
  }

  List<String> get registeredTypes => _adapters.keys.toList();
}
