import 'package:sqflite/sqflite.dart';
import 'package:cat_calories/database/migrations/migration.dart';

class V011AddAuthCredentials extends Migration {
  @override
  int get version => 11;

  @override
  Future<void> up(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS auth_credentials (
        id TEXT PRIMARY KEY NOT NULL,
        server_id TEXT NOT NULL UNIQUE,
        access_token TEXT NOT NULL,
        token_type TEXT NOT NULL DEFAULT 'bearer',
        created_at INT NOT NULL,
        expires_at INT NULL,
        FOREIGN KEY(server_id) REFERENCES sync_servers(id) ON DELETE CASCADE
      )
    ''');
  }
}
