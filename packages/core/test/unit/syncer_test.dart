import 'package:cat_calories_core/features/oauth/domain/auth_credentials.dart';
import 'package:cat_calories_core/features/oauth/domain/auth_credentials_repository.dart';
import 'package:cat_calories_core/features/sync/domain/scoped_server_link.dart';
import 'package:cat_calories_core/features/sync/domain/scoped_server_link_repository.dart';
import 'package:cat_calories_core/features/sync/domain/sync_server.dart';
import 'package:cat_calories_core/features/sync/domain/sync_server_repository.dart';
import 'package:cat_calories_core/features/sync/entity_version.dart';
import 'package:cat_calories_core/features/sync/sync_adapter.dart';
import 'package:cat_calories_core/features/sync/transport/rest/config.dart';
import 'package:cat_calories_core/features/sync/transport/sync_transport.dart';
import 'package:test/test.dart';

// ---------------------------------------------------------------
// Simple in-memory entity for testing
// ---------------------------------------------------------------
class _TestEntity {
  final String id;
  final String profileId;
  final DateTime updatedAt;
  final double value;

  _TestEntity({
    required this.id,
    required this.profileId,
    required this.updatedAt,
    this.value = 0,
  });
}

class _TestAdapter extends SyncAdapter<_TestEntity> {
  @override
  String get entityType => 'test_item';

  @override
  Map<String, dynamic> toSyncPayload(_TestEntity entity) => {
        'id': entity.id,
        'profile_id': entity.profileId,
        'updated_at': entity.updatedAt.millisecondsSinceEpoch,
        'value': entity.value,
      };

  @override
  _TestEntity fromSyncPayload(Map<String, dynamic> json) => _TestEntity(
        id: json['id'] as String,
        profileId: json['profile_id'] as String,
        updatedAt: DateTime.fromMillisecondsSinceEpoch(json['updated_at'] as int),
        value: (json['value'] as num).toDouble(),
      );

  @override
  String extractIdentifier(_TestEntity entity) => entity.id;

  @override
  String extractScope(_TestEntity entity) => entity.profileId;

  @override
  DateTime extractUpdatedAt(_TestEntity entity) => entity.updatedAt;
}

// ---------------------------------------------------------------
// In-memory repository
// ---------------------------------------------------------------
class _InMemoryRepo implements SyncEntityRepository<_TestEntity> {
  final Map<String, _TestEntity> _store = {};

  @override
  Future<List<_TestEntity>> findAllByScopes(Set<String> scopes) async =>
      _store.values.where((e) => scopes.contains(e.profileId)).toList();

  @override
  Future<_TestEntity?> findById(String id) async => _store[id];

  @override
  Future<void> upsert(_TestEntity entity) async => _store[entity.id] = entity;

  @override
  Future<void> deleteById(String id) async => _store.remove(id);

  List<_TestEntity> get all => _store.values.toList();
}

// ---------------------------------------------------------------
// Fake transport
// ---------------------------------------------------------------
class _FakeTransport implements SyncTransport {
  final List<SyncBatch> pushedBatches = [];
  final List<_PullCall> pullCalls = [];

  /// Responses to return for sequential pull() calls.
  final List<PullResult> pullResponses;

  /// Response to return for push() calls.
  SyncResult Function(SyncBatch batch)? pushHandler;

  _FakeTransport({this.pullResponses = const [], this.pushHandler});

  int _pullIndex = 0;

  @override
  Future<SyncResult> push(SyncBatch batch) async {
    pushedBatches.add(batch);
    if (pushHandler != null) return pushHandler!(batch);
    return SyncResult(accepted: batch.entries.length);
  }

  @override
  Future<PullResult> pull({
    required String entityType,
    required String sinceHlc,
    int limit = 100,
  }) async {
    pullCalls.add(_PullCall(entityType, sinceHlc, limit));
    if (_pullIndex < pullResponses.length) {
      return pullResponses[_pullIndex++];
    }
    return const PullResult(entries: []);
  }

  @override
  Future<bool> healthCheck() async => true;

  @override
  Stream<SyncEntry> get remoteChanges => const Stream.empty();

  @override
  Future<void> dispose() async {}
}

class _PullCall {
  final String entityType;
  final String sinceHlc;
  final int limit;
  _PullCall(this.entityType, this.sinceHlc, this.limit);
}

// ---------------------------------------------------------------
// Fake repositories for Syncer dependencies
// ---------------------------------------------------------------
class _FakeServerRepo implements SyncServerRepositoryInterface {
  final List<SyncServer> servers;
  _FakeServerRepo(this.servers);

  @override
  Future<SyncServer?> find(String id) async =>
      servers.where((s) => s.id == id).firstOrNull;
  @override
  Future<List<SyncServer>> findAll() async => servers;
  @override
  Future<SyncServer> insert(SyncServer server) async => server;
  @override
  Future<SyncServer> update(SyncServer server) async => server;
  @override
  Future<int> delete(SyncServer server) async => 1;
}

class _FakeCredsRepo implements AuthCredentialsRepositoryInterface {
  final Map<String, AuthCredentials> _creds = {};

  void add(AuthCredentials creds) => _creds[creds.serverId] = creds;

  @override
  Future<AuthCredentials?> findByServer(String serverId) async =>
      _creds[serverId];
  @override
  Future<AuthCredentials> save(AuthCredentials credentials) async =>
      credentials;
  @override
  Future<int> deleteByServer(String serverId) async => 1;
}

class _FakeLinkRepo implements ScopedServerLinkRepositoryInterface {
  final List<ScopedServerLink> _links = [];

  void add(ScopedServerLink link) => _links.add(link);

  @override
  Future<ScopedServerLink?> find(String id) async =>
      _links.where((l) => l.id == id).firstOrNull;
  @override
  Future<List<ScopedServerLink>> findAll() async => _links;
  @override
  Future<List<ScopedServerLink>> findByServer(String serverId) async =>
      _links.where((l) => l.serverId == serverId).toList();
  @override
  Future<List<ScopedServerLink>> findByScope(String scope) async =>
      _links.where((l) => l.scope == scope).toList();
  @override
  Future<ScopedServerLink> insert(ScopedServerLink link) async => link;
  @override
  Future<int> delete(ScopedServerLink link) async => 1;
}

// ---------------------------------------------------------------
// Testable Syncer subclass that injects a fake transport
// ---------------------------------------------------------------

/// We can't easily mock the transport creation inside Syncer because it
/// creates RestSyncTransport internally. Instead, we test the _push/_pull
/// logic directly via the SyncEngine from sync_transport.dart, which accepts
/// a SyncStorage and SyncTransport. But the actual Syncer class in the app
/// has its own simpler logic. Let's test it by extracting the logic.
///
/// Since Syncer._push and _pull are private, and the class creates its own
/// RestSyncTransport, we'll test the sync logic at the SyncEngine level
/// (which is the designed-for-testability version in sync_transport.dart).

// ---------------------------------------------------------------
// Tests for SyncEngine (the testable engine in sync_transport.dart)
// ---------------------------------------------------------------

class _FakeSyncStorage implements SyncStorage {
  final Map<String, List<({EntityVersion version, Map<String, dynamic> payload})>>
      _pending = {};
  final Map<String, String> _lastPulledHlc = {};
  final List<_ApplyPulledCall> appliedPulls = [];
  final List<_MarkPushedCall> markedPushed = [];

  void addPending(String entityType, EntityVersion version, Map<String, dynamic> payload) {
    _pending.putIfAbsent(entityType, () => []);
    _pending[entityType]!.add((version: version, payload: payload));
  }

  @override
  Future<List<({EntityVersion version, Map<String, dynamic> payload})>>
      findPendingPush({
    required String serverId,
    required String entityType,
    int limit = 100,
  }) async {
    final items = _pending[entityType] ?? [];
    final result = items.take(limit).toList();
    // Simulate consuming: remove returned items
    if (result.isNotEmpty) {
      _pending[entityType] = items.sublist(result.length);
    }
    return result;
  }

  @override
  Future<void> markPushed({
    required String entityId,
    required String entityType,
    required String serverId,
    required int version,
  }) async {
    markedPushed.add(_MarkPushedCall(entityId, entityType, serverId, version));
  }

  @override
  Future<void> applyPulled({
    required String entityType,
    required List<SyncEntry> entries,
    required String serverId,
  }) async {
    appliedPulls.add(_ApplyPulledCall(entityType, entries, serverId));
  }

  @override
  Future<String?> getLastPulledHlc({
    required String entityType,
    required String serverId,
  }) async {
    return _lastPulledHlc['$entityType:$serverId'];
  }

  @override
  Future<void> setLastPulledHlc({
    required String entityType,
    required String serverId,
    required String hlc,
  }) async {
    _lastPulledHlc['$entityType:$serverId'] = hlc;
  }
}

class _ApplyPulledCall {
  final String entityType;
  final List<SyncEntry> entries;
  final String serverId;
  _ApplyPulledCall(this.entityType, this.entries, this.serverId);
}

class _MarkPushedCall {
  final String entityId;
  final String entityType;
  final String serverId;
  final int version;
  _MarkPushedCall(this.entityId, this.entityType, this.serverId, this.version);
}

void main() {
  // =================================================================
  // SyncEngine tests (the designed-for-test engine in sync_transport.dart)
  // =================================================================
  group('SyncEngine', () {
    late SyncAdapterRegistry registry;
    late _FakeSyncStorage storage;
    late _FakeTransport transport;
    late SyncEngine engine;

    const serverId = 'server-1';
    const serverUrl = 'http://localhost:9999';

    setUp(() {
      registry = SyncAdapterRegistry();
      registry.register(_TestAdapter(), _InMemoryRepo());
      storage = _FakeSyncStorage();
      transport = _FakeTransport();
      engine = SyncEngine(registry: registry, storage: storage);

      engine.addServer(ServerConnection(
        serverId: serverId,
        serverUrl: serverUrl,
        transport: transport,
        scopeIds: {'profile-1'},
      ));
    });

    group('push', () {
      test('pushes pending items in batches', () async {
        // Add 3 pending items
        for (var i = 0; i < 3; i++) {
          storage.addPending(
            'test_item',
            EntityVersion(
              entityId: 'e$i',
              entityType: 'test_item',
              version: 1,
              hlcTimestamp: '${1000 + i}-0',
              isDeleted: false,
              updatedAt: DateTime.now(),
            ),
            {'id': 'e$i', 'profile_id': 'profile-1', 'updated_at': 1000 + i, 'value': i * 10.0},
          );
        }

        final result = await engine.syncServer(serverId);
        expect(result.totalPushed, 3);
        expect(transport.pushedBatches.length, 1);
        expect(transport.pushedBatches.first.entries.length, 3);
      });

      test('marks each entry as pushed after successful push', () async {
        storage.addPending(
          'test_item',
          EntityVersion(
            entityId: 'e1',
            entityType: 'test_item',
            version: 1,
            hlcTimestamp: '1000-0',
            isDeleted: false,
            updatedAt: DateTime.now(),
          ),
          {'id': 'e1', 'profile_id': 'profile-1', 'updated_at': 1000, 'value': 50.0},
        );

        await engine.syncServer(serverId);
        expect(storage.markedPushed.length, 1);
        expect(storage.markedPushed.first.entityId, 'e1');
        expect(storage.markedPushed.first.serverId, serverId);
      });

      test('sends nothing when no pending items', () async {
        final result = await engine.syncServer(serverId);
        expect(result.totalPushed, 0);
        expect(transport.pushedBatches, isEmpty);
      });
    });

    group('pull', () {
      test('applies pulled entries to storage', () async {
        transport = _FakeTransport(pullResponses: [
          PullResult(
            entries: [
              SyncEntry(
                entityId: 'r1',
                version: 1,
                hlc: '5000-0',
                isDeleted: false,
                payload: {'id': 'r1', 'profile_id': 'profile-1', 'updated_at': 5000, 'value': 100.0},
              ),
            ],
            hasMore: false,
            serverTimestamp: '5000-0',
          ),
        ]);

        engine = SyncEngine(registry: registry, storage: storage);
        engine.addServer(ServerConnection(
          serverId: serverId,
          serverUrl: serverUrl,
          transport: transport,
          scopeIds: {'profile-1'},
        ));

        final result = await engine.syncServer(serverId);
        expect(result.totalPulled, 1);
        expect(storage.appliedPulls.length, 1);
        expect(storage.appliedPulls.first.entries.first.entityId, 'r1');
      });

      test('paginates pull when hasMore is true', () async {
        transport = _FakeTransport(pullResponses: [
          PullResult(
            entries: [
              SyncEntry(entityId: 'r1', version: 1, hlc: '1000-0', isDeleted: false,
                  payload: {'id': 'r1', 'profile_id': 'p', 'updated_at': 1000, 'value': 1}),
            ],
            hasMore: true,
            serverTimestamp: '1000-0',
          ),
          PullResult(
            entries: [
              SyncEntry(entityId: 'r2', version: 1, hlc: '2000-0', isDeleted: false,
                  payload: {'id': 'r2', 'profile_id': 'p', 'updated_at': 2000, 'value': 2}),
            ],
            hasMore: false,
            serverTimestamp: '2000-0',
          ),
        ]);

        engine = SyncEngine(registry: registry, storage: storage);
        engine.addServer(ServerConnection(
          serverId: serverId,
          serverUrl: serverUrl,
          transport: transport,
          scopeIds: {'profile-1'},
        ));

        final result = await engine.syncServer(serverId);
        expect(result.totalPulled, 2);
        expect(transport.pullCalls.length, 2);
        // Second call uses the serverTimestamp from first response
        expect(transport.pullCalls[1].sinceHlc, '1000-0');
      });

      test('saves lastPulledHlc after each pull page', () async {
        transport = _FakeTransport(pullResponses: [
          PullResult(
            entries: [
              SyncEntry(entityId: 'r1', version: 1, hlc: '3000-0', isDeleted: false,
                  payload: {'id': 'r1', 'profile_id': 'p', 'updated_at': 3000, 'value': 1}),
            ],
            hasMore: false,
            serverTimestamp: '3000-0',
          ),
        ]);

        engine = SyncEngine(registry: registry, storage: storage);
        engine.addServer(ServerConnection(
          serverId: serverId,
          serverUrl: serverUrl,
          transport: transport,
          scopeIds: {'profile-1'},
        ));

        await engine.syncServer(serverId);

        final savedHlc = await storage.getLastPulledHlc(
          entityType: 'test_item',
          serverId: serverId,
        );
        expect(savedHlc, '3000-0');
      });

      test('stops pulling when entries are empty', () async {
        transport = _FakeTransport(pullResponses: [
          const PullResult(entries: [], hasMore: false),
        ]);

        engine = SyncEngine(registry: registry, storage: storage);
        engine.addServer(ServerConnection(
          serverId: serverId,
          serverUrl: serverUrl,
          transport: transport,
          scopeIds: {'profile-1'},
        ));

        final result = await engine.syncServer(serverId);
        expect(result.totalPulled, 0);
        expect(transport.pullCalls.length, 1);
      });
    });

    group('server management', () {
      test('skips inactive server', () async {
        engine.removeServer(serverId);
        engine.addServer(ServerConnection(
          serverId: serverId,
          serverUrl: serverUrl,
          transport: transport,
          scopeIds: {'profile-1'},
          isActive: false,
        ));

        final result = await engine.syncServer(serverId);
        expect(result.status, SyncSessionStatus.skipped);
      });

      test('returns unreachable when health check fails', () async {
        final unhealthyTransport = _UnhealthyTransport();
        engine.removeServer(serverId);
        engine.addServer(ServerConnection(
          serverId: serverId,
          serverUrl: serverUrl,
          transport: unhealthyTransport,
          scopeIds: {'profile-1'},
        ));

        final result = await engine.syncServer(serverId);
        expect(result.status, SyncSessionStatus.unreachable);
      });

      test('returns skipped for unknown server', () async {
        final result = await engine.syncServer('nonexistent');
        expect(result.status, SyncSessionStatus.skipped);
      });

      test('syncAll syncs all registered servers', () async {
        // Add a second server
        final transport2 = _FakeTransport();
        engine.addServer(ServerConnection(
          serverId: 'server-2',
          serverUrl: 'http://localhost:9998',
          transport: transport2,
          scopeIds: {'profile-1'},
        ));

        final results = await engine.syncAll();
        expect(results.length, 2);
      });
    });
  });

  // =================================================================
  // SyncAdapterRegistry tests
  // =================================================================
  group('SyncAdapterRegistry', () {
    test('register and retrieve adapter', () {
      final registry = SyncAdapterRegistry();
      final adapter = _TestAdapter();
      final repo = _InMemoryRepo();
      registry.register(adapter, repo);

      expect(registry.registeredTypes, contains('test_item'));
      expect(registry.getAdapter<_TestEntity>('test_item'), same(adapter));
      expect(registry.getRepository<_TestEntity>('test_item'), same(repo));
    });

    test('throws for unregistered type', () {
      final registry = SyncAdapterRegistry();
      expect(() => registry.getAdapter<_TestEntity>('missing'), throwsStateError);
      expect(() => registry.getRepository<_TestEntity>('missing'), throwsStateError);
    });

    test('forEach visits all registrations', () async {
      final registry = SyncAdapterRegistry();
      registry.register(_TestAdapter(), _InMemoryRepo());

      var visited = 0;
      await registry.forEach(<T>(adapter, repo) async {
        visited++;
        expect(adapter.entityType, 'test_item');
      });
      expect(visited, 1);
    });
  });

  // =================================================================
  // SyncTransport types tests
  // =================================================================
  group('SyncEntry', () {
    test('toJson / fromJson round-trip', () {
      const entry = SyncEntry(
        entityId: 'e1',
        version: 3,
        hlc: '5000-0',
        isDeleted: false,
        payload: {'foo': 'bar'},
      );
      final json = entry.toJson();
      final restored = SyncEntry.fromJson(json);
      expect(restored.entityId, 'e1');
      expect(restored.version, 3);
      expect(restored.hlc, '5000-0');
      expect(restored.isDeleted, isFalse);
      expect(restored.payload?['foo'], 'bar');
    });

    test('toJson omits payload when null', () {
      const entry = SyncEntry(
        entityId: 'e1',
        version: 1,
        hlc: '1000-0',
        isDeleted: true,
      );
      final json = entry.toJson();
      expect(json.containsKey('payload'), isFalse);
    });
  });
}

/// Transport that always fails health check.
class _UnhealthyTransport implements SyncTransport {
  @override
  Future<SyncResult> push(SyncBatch batch) async =>
      SyncResult(accepted: batch.entries.length);

  @override
  Future<PullResult> pull({
    required String entityType,
    required String sinceHlc,
    int limit = 100,
  }) async =>
      const PullResult(entries: []);

  @override
  Future<bool> healthCheck() async => false;

  @override
  Stream<SyncEntry> get remoteChanges => const Stream.empty();

  @override
  Future<void> dispose() async {}
}
