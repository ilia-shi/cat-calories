import 'package:cat_calories/database/database_client.dart';
import 'package:cat_calories/features/oauth/domain/auth_credentials.dart';
import 'package:cat_calories/features/oauth/domain/auth_credentials_repository.dart';

class AuthCredentialsRepository implements AuthCredentialsRepositoryInterface {
  final DatabaseClient _db;
  static const _table = 'auth_credentials';

  AuthCredentialsRepository(this._db);

  @override
  Future<AuthCredentials?> findByServer(String serverId) async {
    final rows = await _db.query(
      _table,
      where: 'server_id = ?',
      whereArgs: [serverId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return AuthCredentials.fromJson(rows.first);
  }

  @override
  Future<AuthCredentials> save(AuthCredentials credentials) async {
    final existing = await findByServer(credentials.serverId);
    if (existing != null) {
      await _db.update(
        _table,
        credentials.toJson(),
        where: 'server_id = ?',
        whereArgs: [credentials.serverId],
      );
    } else {
      await _db.insert(_table, credentials.toJson());
    }
    return credentials;
  }

  @override
  Future<int> deleteByServer(String serverId) async {
    return _db.delete(
      _table,
      where: 'server_id = ?',
      whereArgs: [serverId],
    );
  }
}
