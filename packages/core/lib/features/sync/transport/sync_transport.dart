import '../sync_adapter.dart';
import '../entity_version.dart';

final class SyncBatch {
  final String idempotencyKey;
  final String entityType;
  final List<SyncEntry> entries;

  const SyncBatch({
    required this.idempotencyKey,
    required this.entityType,
    required this.entries,
  });
}

final class SyncEntry {
  final String entityId;
  final int version;
  final String hlc;
  final bool isDeleted;
  final Map<String, dynamic>? payload; // null если isDeleted

  const SyncEntry({
    required this.entityId,
    required this.version,
    required this.hlc,
    required this.isDeleted,
    this.payload,
  });

  Map<String, dynamic> toJson() => {
        'entity_id': entityId,
        'version': version,
        'hlc': hlc,
        'is_deleted': isDeleted,
        if (payload != null) 'payload': payload,
      };

  factory SyncEntry.fromJson(Map<String, dynamic> json) => SyncEntry(
        entityId: json['entity_id'] as String,
        version: json['version'] as int,
        hlc: json['hlc'] as String,
        isDeleted: json['is_deleted'] as bool,
        payload: json['payload'] as Map<String, dynamic>?,
      );
}

final class SyncResult {
  final int accepted;
  final int rejected;
  final List<SyncConflict> conflicts;
  final String? serverTimestamp;

  const SyncResult({
    required this.accepted,
    this.rejected = 0,
    this.conflicts = const [],
    this.serverTimestamp,
  });
}

final class SyncConflict {
  final String entityId;
  final SyncEntry localVersion;
  final SyncEntry serverVersion;

  const SyncConflict({
    required this.entityId,
    required this.localVersion,
    required this.serverVersion,
  });
}

final class PullResult {
  final List<SyncEntry> entries;
  final bool hasMore;
  final String? serverTimestamp;

  const PullResult({
    required this.entries,
    this.hasMore = false,
    this.serverTimestamp,
  });
}

abstract class SyncTransport {
  Future<SyncResult> push(SyncBatch batch);
  Future<PullResult> pull({
    required String entityType,
    required String sinceHlc,
    required int limit,
  });

  Future<bool> healthCheck();

  /// Для транспортов с поддержкой push-уведомлений (WS, SSE).
  /// REST реализация просто возвращает пустой Stream.
  Stream<SyncEntry> get remoteChanges;

  Future<void> dispose();
}

final class ServerConnection {
  final String serverId;
  final String serverUrl;
  final SyncTransport transport;
  final Set<String> scopeIds;
  final bool isActive;

  const ServerConnection({
    required this.serverId,
    required this.serverUrl,
    required this.transport,
    required this.scopeIds,
    this.isActive = true,
  });
}

/// Хранилище, из которого engine читает версии и реплики.
/// Реализуется приложением (через Room, Drift, sqflite и т.д.)
abstract class SyncStorage {
  /// Сущности, которые нужно отправить на конкретный сервер
  Future<List<({EntityVersion version, Map<String, dynamic> payload})>>
      findPendingPush({
    required String serverId,
    required String entityType,
    int limit = 100,
  });

  /// Обновить ReplicaState после успешного push
  Future<void> markPushed({
    required String entityId,
    required String entityType,
    required String serverId,
    required int version,
  });

  /// Применить входящие изменения
  Future<void> applyPulled({
    required String entityType,
    required List<SyncEntry> entries,
    required String serverId,
  });

  /// Получить sync anchor для pull
  Future<String?> getLastPulledHlc({
    required String entityType,
    required String serverId,
  });

  /// Сохранить sync anchor после pull
  Future<void> setLastPulledHlc({
    required String entityType,
    required String serverId,
    required String hlc,
  });
}

class SyncEngine {
  final SyncAdapterRegistry _registry;
  final SyncStorage _storage;
  final Map<String, ServerConnection> _servers = {};
  final int batchSize = 100;


  SyncEngine({
    required SyncAdapterRegistry registry,
    required SyncStorage storage,
  })  : _registry = registry,
        _storage = storage;

  // --- Управление серверами ---

  void addServer(ServerConnection connection) {
    _servers[connection.serverId] = connection;
  }

  void removeServer(String serverId) {
    _servers.remove(serverId);
  }

  Future<SyncSessionResult> syncServer(String serverId) async {
    final server = _servers[serverId];
    if (server == null || !server.isActive) {
      return SyncSessionResult.skipped(serverId);
    }

    final transport = server.transport;

    // Health check
    final isHealthy = await transport.healthCheck();
    if (!isHealthy) {
      return SyncSessionResult.unreachable(serverId);
    }

    int totalPushed = 0;
    int totalPulled = 0;
    final errors = <String>[];

    for (final entityType in _registry.registeredTypes) {
      try {
        // --- PUSH ---
        final pushed = await _pushEntityType(
          serverId: serverId,
          entityType: entityType,
          transport: transport,
        );
        totalPushed += pushed;

        // --- PULL ---
        final pulled = await _pullEntityType(
          serverId: serverId,
          entityType: entityType,
          transport: transport,
        );
        totalPulled += pulled;
      } catch (e) {
        errors.add('$entityType: $e');
      }
    }

    return SyncSessionResult(
      serverId: serverId,
      status: errors.isEmpty
          ? SyncSessionStatus.success
          : SyncSessionStatus.partial,
      totalPushed: totalPushed,
      totalPulled: totalPulled,
      errors: errors,
      completedAt: DateTime.now(),
    );
  }

  /// Синхронизация со всеми активными серверами
  Future<List<SyncSessionResult>> syncAll() async {
    final results = <SyncSessionResult>[];
    for (final serverId in _servers.keys) {
      results.add(await syncServer(serverId));
    }
    return results;
  }

  // --- Push ---

  Future<int> _pushEntityType({
    required String serverId,
    required String entityType,
    required SyncTransport transport,
  }) async {
    int totalPushed = 0;

    while (true) {
      final pending = await _storage.findPendingPush(
        serverId: serverId,
        entityType: entityType,
        limit: batchSize,
      );

      if (pending.isEmpty) break;

      final batch = SyncBatch(
        idempotencyKey: _generateUuid(),
        entityType: entityType,
        entries: pending
            .map((p) => SyncEntry(
                  entityId: p.version.entityId,
                  version: p.version.version,
                  hlc: p.version.hlcTimestamp,
                  isDeleted: p.version.isDeleted,
                  payload: p.version.isDeleted ? null : p.payload,
                ))
            .toList(),
      );

      final result = await transport.push(batch);

      // Помечаем отправленные записи
      for (final entry in batch.entries) {
        await _storage.markPushed(
          entityId: entry.entityId,
          entityType: entityType,
          serverId: serverId,
          version: entry.version,
        );
      }

      totalPushed += result.accepted;

      // Если отправили меньше 100, значит всё отправлено
      if (pending.length < batchSize) {
        break;
      }
    }

    return totalPushed;
  }

  // --- Pull ---

  Future<int> _pullEntityType({
    required String serverId,
    required String entityType,
    required SyncTransport transport,
  }) async {
    int totalPulled = 0;

    while (true) {
      final sinceHlc = await _storage.getLastPulledHlc(
            entityType: entityType,
            serverId: serverId,
          ) ??
          '';

      final result = await transport.pull(
        entityType: entityType,
        sinceHlc: sinceHlc,
        limit: batchSize,
      );

      if (result.entries.isEmpty) break;

      await _storage.applyPulled(
        entityType: entityType,
        entries: result.entries,
        serverId: serverId,
      );

      if (result.serverTimestamp != null) {
        await _storage.setLastPulledHlc(
          entityType: entityType,
          serverId: serverId,
          hlc: result.serverTimestamp!,
        );
      }

      totalPulled += result.entries.length;

      if (!result.hasMore) break;
    }

    return totalPulled;
  }

  String _generateUuid() {
    return DateTime.now().microsecondsSinceEpoch.toRadixString(36);
  }
}

// ---------------------
// Результат сессии
// ---------------------

enum SyncSessionStatus { success, partial, unreachable, skipped }

final class SyncSessionResult {
  final String serverId;
  final SyncSessionStatus status;
  final int totalPushed;
  final int totalPulled;
  final List<String> errors;
  final DateTime completedAt;

  const SyncSessionResult({
    required this.serverId,
    required this.status,
    this.totalPushed = 0,
    this.totalPulled = 0,
    this.errors = const [],
    required this.completedAt,
  });

  factory SyncSessionResult.skipped(String serverId) => SyncSessionResult(
        serverId: serverId,
        status: SyncSessionStatus.skipped,
        completedAt: DateTime.now(),
      );

  factory SyncSessionResult.unreachable(String serverId) => SyncSessionResult(
        serverId: serverId,
        status: SyncSessionStatus.unreachable,
        completedAt: DateTime.now(),
      );
}

// ============================================================
// REST TRANSPORT — реализация SyncTransport для HTTP REST API
// ============================================================

// В реальном проекте: import 'package:http/http.dart' as http;
// или import 'package:dio/dio.dart';

// ---------------------
// Исключения транспорта
// ---------------------

class SyncTransportException implements Exception {
  final String message;
  final int? statusCode;

  const SyncTransportException(this.message, {this.statusCode});

  @override
  String toString() => 'SyncTransportException($statusCode): $message';
}

class SyncAuthException extends SyncTransportException {
  const SyncAuthException(super.message) : super(statusCode: 401);
}

// ============================================================
// ПРИМЕР: Scheduler — запускает sync по триггерам
// ============================================================


// ============================================================
// ПРИМЕР: Как приложение собирает всё вместе
// ============================================================

// void main() {
//   // 1. Регистрируем адаптеры
//   final registry = SyncAdapterRegistry()
//     ..register(FoodEntrySyncAdapter())
//     ..register(ActivitySyncAdapter())
//     ..register(ProfileSyncAdapter());
//
//   // 2. Создаём хранилище (Drift/sqflite)
//   final storage = DriftSyncStorage(database);
//
//   // 3. Создаём engine
//   final engine = SyncEngine(
//     registry: registry,
//     storage: storage,
//   );
//
//   // 4. Подключаем сервер
//   engine.addServer(ServerConnection(
//     serverId: 'server-main',
//     serverUrl: 'https://sync.myapp.com',
//     transport: RestSyncTransport(
//       baseUrl: 'https://sync.myapp.com',
//       getAccessToken: () => authManager.getValidToken(),
//     ),
//     profileIds: {'profile-me', 'profile-cat'},
//   ));
//
//   // 5. Запускаем scheduler
//   final scheduler = SyncScheduler(engine)
//     ..startPeriodic(const Duration(minutes: 5))
//     ..watchConnectivity();
//
//   // 6. Кнопка Sync в UI
//   onSyncButtonPressed: () => scheduler.syncNow();
// }
