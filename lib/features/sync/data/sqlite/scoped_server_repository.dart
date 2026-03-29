import 'package:cat_calories/database/database_client.dart';
import 'package:cat_calories_core/features/sync/domain/scoped_server_link.dart';
import 'package:cat_calories_core/features/sync/domain/scoped_server_link_repository.dart';

final class ScopedServerLinkRepository
    implements ScopedServerLinkRepositoryInterface {
  static const String tableName = 'scoped_server_links';
  final DatabaseClient _db;

  ScopedServerLinkRepository(this._db);

  @override
  Future<ScopedServerLink?> find(String id) async {
    final result = await _db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (result.isNotEmpty) {
      return ScopedServerLink.fromJson(result.first);
    }
    return null;
  }

  @override
  Future<List<ScopedServerLink>> findAll() async {
    final result = await _db.query(tableName);
    return result.map((e) => ScopedServerLink.fromJson(e)).toList();
  }

  @override
  Future<List<ScopedServerLink>> findByServer(String serverId) async {
    final result = await _db.query(
      tableName,
      where: 'server_id = ?',
      whereArgs: [serverId],
    );
    return result.map((e) => ScopedServerLink.fromJson(e)).toList();
  }

  @override
  Future<List<ScopedServerLink>> findByScope(String scope) async {
    final result = await _db.query(
      tableName,
      where: 'scope = ?',
      whereArgs: [scope],
    );
    return result.map((e) => ScopedServerLink.fromJson(e)).toList();
  }

  @override
  Future<ScopedServerLink> insert(ScopedServerLink link) async {
    await _db.insert(tableName, link.toJson());
    return link;
  }

  @override
  Future<int> delete(ScopedServerLink link) async {
    return await _db.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [link.id],
    );
  }
}
