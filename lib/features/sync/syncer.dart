import 'dart:io';

import 'package:cat_calories/common/synced_folder.dart';
import 'package:cat_calories_core/features/oauth/domain/auth_credentials_repository.dart';
import 'package:cat_calories_core/features/profile/domain/profile_repository_interface.dart';
import 'package:cat_calories_core/features/sync/discover_server.dart';
import 'package:cat_calories_core/features/sync/domain/scoped_server_link_repository.dart';
import 'package:cat_calories_core/features/sync/domain/sync_server.dart';
import 'package:cat_calories_core/features/sync/domain/sync_server_repository.dart';
import 'package:cat_calories_core/features/sync/sync_adapter.dart';
import 'package:cat_calories_core/features/sync/transport/file/device_identity.dart';
import 'package:cat_calories_core/features/sync/transport/file/file_cursor_store.dart';
import 'package:cat_calories_core/features/sync/transport/file/file_sync_transport.dart';
import 'package:cat_calories_core/features/sync/transport/file/ndjson_log.dart';
import 'package:cat_calories_core/features/sync/transport/rest/transport.dart';
import 'package:cat_calories_core/features/sync/transport/sync_transport.dart';
import 'package:path_provider/path_provider.dart';

class Syncer {
  final SyncServerRepositoryInterface _serverRepo;
  final AuthCredentialsRepositoryInterface _credentialsRepo;
  final ScopedServerLinkRepositoryInterface _linkRepo;
  final ProfileRepositoryInterface _profileRepo;
  final SyncAdapterRegistry _registry;

  Syncer({
    required SyncServerRepositoryInterface serverRepo,
    required AuthCredentialsRepositoryInterface credentialsRepo,
    required ScopedServerLinkRepositoryInterface linkRepo,
    required ProfileRepositoryInterface profileRepo,
    required SyncAdapterRegistry registry,
  })  : _serverRepo = serverRepo,
        _credentialsRepo = credentialsRepo,
        _linkRepo = linkRepo,
        _profileRepo = profileRepo,
        _registry = registry;

  Future<SyncResult> syncAll() async {
    final servers = await _serverRepo.findAll();
    final results = <ServerSyncResult>[];
    for (final server in servers) {
      results.add(await syncServer(server));
    }
    if (await SyncedFolder.isFileSyncEnabled()) {
      final rootPath = await SyncedFolder.getPath();
      if (rootPath != null) {
        results.add(await syncFolder(rootPath));
      }
    }
    return SyncResult(results);
  }

  /// Folder-based sync (Syncthing): same push/pull semantics as a server,
  /// but the transport is append-only logs in the shared folder. Scope is
  /// every local profile — folder trust equals device trust.
  Future<ServerSyncResult> syncFolder(String rootPath) async {
    final support = await getApplicationSupportDirectory();
    final localDir = Directory('${support.path}/file_sync');

    final String deviceId;
    try {
      deviceId = await DeviceIdentity.ensure(
        localFile: File('${localDir.path}/device_id'),
        syncRoot: Directory(rootPath),
      );
    } catch (e) {
      return ServerSyncResult.failed('Folder not writable: $e');
    }

    final transport = FileSyncTransport(
      root: Directory(rootPath),
      deviceId: deviceId,
      cursors: JsonFileCursorStore(File('${localDir.path}/cursors.json')),
    );

    if (!await transport.healthCheck()) {
      return ServerSyncResult.failed('Folder not writable: $rootPath');
    }

    final profiles = await _profileRepo.fetchAll();
    final scopes = {
      for (final profile in profiles)
        if (profile.id != null) profile.id!,
    };

    try {
      int totalPushed = 0;
      int totalPulled = 0;
      int totalDeleted = 0;

      await _registry.forEach(<T>(adapter, repo) async {
        final pushed =
            await _pushToFolder<T>(transport, adapter, repo, scopes);
        final (pulled, deleted) =
            await _pull<T>(transport, adapter, repo, scopes);
        totalPushed += pushed;
        totalPulled += pulled;
        totalDeleted += deleted;
      });

      return ServerSyncResult(
        pushed: totalPushed,
        pulled: totalPulled,
        deleted: totalDeleted,
      );
    } catch (e) {
      return ServerSyncResult.failed('Folder sync failed: $e');
    } finally {
      await transport.dispose();
    }
  }

  /// Unlike the REST push (where re-sending everything is a server-side
  /// no-op), appending to a log grows it forever — so push only entities
  /// whose updatedAt is newer than the last line already in our own log.
  Future<int> _pushToFolder<T>(
    FileSyncTransport transport,
    SyncAdapter<T> adapter,
    SyncEntityRepository<T> repo,
    Set<String> linkedScopes,
  ) async {
    final ownLog = File(
        '${transport.root.path}/v1/logs/${transport.deviceId}/${adapter.entityType}.ndjson');
    final lastPushed = <String, DateTime>{};
    final read =
        await NdjsonLog.read(ownLog, fromOffset: 0, maxLines: 1 << 30);
    for (final line in read.lines) {
      final id = line['entity_id'];
      final hlc = line['hlc'];
      if (id is! String || hlc is! String) {
        continue;
      }
      final at = DateTime.tryParse(hlc);
      if (at != null &&
          (lastPushed[id] == null || at.isAfter(lastPushed[id]!))) {
        lastPushed[id] = at;
      }
    }

    final entities = await repo.findAllByScopes(linkedScopes);
    final changed = entities.where((entity) {
      final last = lastPushed[adapter.extractIdentifier(entity)];
      return last == null ||
          adapter.extractUpdatedAt(entity).toUtc().isAfter(last);
    }).toList();

    if (changed.isEmpty) {
      return 0;
    }
    final entries = changed
        .map((entity) => SyncEntry(
              entityId: adapter.extractIdentifier(entity),
              version: 1,
              hlc: adapter.extractUpdatedAt(entity).toUtc().toIso8601String(),
              isDeleted: false,
              payload: adapter.toSyncPayload(entity),
            ))
        .toList();

    final result = await transport.push(SyncBatch(
      idempotencyKey:
          DateTime.now().microsecondsSinceEpoch.toRadixString(36),
      entityType: adapter.entityType,
      entries: entries,
    ));
    return result.accepted;
  }

  Future<ServerSyncResult> syncServer(SyncServer server) async {
    final creds = await _credentialsRepo.findByServer(server.id);
    if (creds == null) {
      return ServerSyncResult.failed('No credentials');
    }

    final links = await _linkRepo.findByServer(server.id);
    if (links.isEmpty) {
      return ServerSyncResult.failed('No linked profiles');
    }

    final linkedScopes = links.map((l) => l.scope).toSet();

    Object? lastError;
    for (final url in server.serverUrls) {
      final baseUrl = normalizeServerUrl(url);
      final transport = RestSyncTransport(
        baseUrl: baseUrl,
        getAccessToken: () => Future.value(creds.accessToken),
        timeout: const Duration(seconds: 30),
      );

      try {
        int totalPushed = 0;
        int totalPulled = 0;
        int totalDeleted = 0;

        await _registry.forEach(<T>(adapter, repo) async {
          final pushed = await _push<T>(transport, adapter, repo, linkedScopes);
          final (pulled, deleted) =
              await _pull<T>(transport, adapter, repo, linkedScopes);
          totalPushed += pushed;
          totalPulled += pulled;
          totalDeleted += deleted;
        });

        return ServerSyncResult(
          pushed: totalPushed,
          pulled: totalPulled,
          deleted: totalDeleted,
        );
      } catch (e) {
        lastError = e;
      } finally {
        await transport.dispose();
      }
    }

    return ServerSyncResult.failed('All URLs failed: $lastError');
  }

  Future<int> _push<T>(
    SyncTransport transport,
    SyncAdapter<T> adapter,
    SyncEntityRepository<T> repo,
    Set<String> linkedScopes,
  ) async {
    final entities = await repo.findAllByScopes(linkedScopes);

    int totalPushed = 0;
    const batchSize = 100;

    for (var i = 0; i < entities.length; i += batchSize) {
      final end =
          (i + batchSize > entities.length) ? entities.length : i + batchSize;
      final batch = entities.sublist(i, end);

      final entries = batch
          .map((entity) => SyncEntry(
                entityId: adapter.extractIdentifier(entity),
                version: 1,
                hlc: adapter.extractUpdatedAt(entity).toUtc().toIso8601String(),
                isDeleted: false,
                payload: adapter.toSyncPayload(entity),
              ))
          .toList();

      final syncBatch = SyncBatch(
        idempotencyKey:
            '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}-$i',
        entityType: adapter.entityType,
        entries: entries,
      );

      final result = await transport.push(syncBatch);
      totalPushed += result.accepted;
    }

    return totalPushed;
  }

  Future<(int, int)> _pull<T>(
    SyncTransport transport,
    SyncAdapter<T> adapter,
    SyncEntityRepository<T> repo,
    Set<String> linkedScopes,
  ) async {
    int totalPulled = 0;
    int totalDeleted = 0;
    String sinceHlc = '';
    const batchSize = 100;

    while (true) {
      final pullResult = await transport.pull(
        entityType: adapter.entityType,
        sinceHlc: sinceHlc,
        limit: batchSize,
      );

      for (final entry in pullResult.entries) {
        if (entry.isDeleted) {
          if (entry.entityId.isNotEmpty) {
            final existing = await repo.findById(entry.entityId);
            if (existing != null) {
              await repo.deleteById(entry.entityId);
              totalDeleted++;
            }
          }
        } else if (entry.payload != null) {
          final entity = adapter.fromSyncPayload(entry.payload!);
          final id = adapter.extractIdentifier(entity);
          final scope = adapter.extractScope(entity);
          if (linkedScopes.contains(scope)) {
            final existing = await repo.findById(id);
            if (existing == null) {
              await repo.upsert(entity);
              totalPulled++;
            } else if (adapter
                .extractUpdatedAt(entity)
                .isAfter(adapter.extractUpdatedAt(existing))) {
              await repo.upsert(entity);
              totalPulled++;
            }
          }
        }
      }

      if (!pullResult.hasMore || pullResult.serverTimestamp == null) {
        break;
      }
      sinceHlc = pullResult.serverTimestamp!;
    }

    return (totalPulled, totalDeleted);
  }
}

final class SyncResult {
  final List<ServerSyncResult> serverResults;

  SyncResult(this.serverResults);

  int get totalPushed =>
      serverResults.fold(0, (sum, r) => sum + r.pushed);

  int get totalPulled =>
      serverResults.fold(0, (sum, r) => sum + r.pulled);

  int get totalDeleted =>
      serverResults.fold(0, (sum, r) => sum + r.deleted);

  int get totalFailed =>
      serverResults.where((r) => r.isFailed).length;

  bool get hasChanges => totalPulled > 0 || totalDeleted > 0;

  String get message {
    if (serverResults.isNotEmpty &&
        totalFailed == serverResults.length) {
      return 'Sync failed';
    }
    final parts = <String>[];
    if (totalPushed > 0) {
      parts.add('$totalPushed pushed');
    }
    if (totalPulled > 0) {
      parts.add('$totalPulled pulled');
    }
    if (totalDeleted > 0) {
      parts.add('$totalDeleted deleted');
    }
    if (parts.isEmpty) {
      return 'Synced, no changes';
    }
    return 'Synced: ${parts.join(', ')}';
  }
}

final class ServerSyncResult {
  final int pushed;
  final int pulled;
  final int deleted;
  final bool isFailed;
  final String? error;

  ServerSyncResult({
    this.pushed = 0,
    this.pulled = 0,
    this.deleted = 0,
    this.isFailed = false,
    this.error,
  });

  factory ServerSyncResult.failed(String error) =>
      ServerSyncResult(isFailed: true, error: error);

  String get message {
    final parts = <String>[];
    if (pushed > 0) {
      parts.add('$pushed pushed');
    }
    if (pulled > 0) {
      parts.add('$pulled pulled');
    }
    if (deleted > 0) {
      parts.add('$deleted deleted');
    }
    if (parts.isEmpty) {
      return 'Synced, no changes';
    }
    return 'Synced: ${parts.join(', ')}';
  }
}
