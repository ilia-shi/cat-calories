import 'package:cat_calories/database/database_client.dart';
import '../../domain/sync_server.dart';
import '../../domain/sync_server_repository.dart';

final class SyncServerRepository implements SyncServerRepositoryInterface {
  static const String tableName = 'sync_servers';
  final DatabaseClient _db;

  SyncServerRepository(this._db);

  @override
  Future<SyncServer?> find(String id) async {
    final result = await _db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (result.isNotEmpty) {
      return SyncServer.fromJson(result.first);
    }
    return null;
  }

  @override
  Future<List<SyncServer>> findAll() async {
    final result = await _db.query(tableName, orderBy: 'created_at DESC');
    return result.map((e) => SyncServer.fromJson(e)).toList();
  }

  @override
  Future<SyncServer> insert(SyncServer server) async {
    await _db.insert(tableName, server.toJson());
    return server;
  }

  @override
  Future<SyncServer> update(SyncServer server) async {
    await _db.update(
      tableName,
      server.toJson(),
      where: 'id = ?',
      whereArgs: [server.id],
    );
    return server;
  }

  @override
  Future<int> delete(SyncServer server) async {
    return await _db.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [server.id],
    );
  }
}
