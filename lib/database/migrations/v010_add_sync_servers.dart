import 'package:sqflite/sqflite.dart';
import 'package:cat_calories/database/migrations/migration.dart';

class V010AddSyncServers extends Migration {
  @override
  int get version => 10;

  @override
  Future<void> up(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sync_servers (
        id TEXT PRIMARY KEY NOT NULL,
        display_name TEXT NOT NULL,
        server_url TEXT NOT NULL,
        transport_type TEXT NOT NULL DEFAULT 'rest',
        transport_json TEXT NOT NULL,
        is_active INT NOT NULL DEFAULT 1,
        created_at INT NOT NULL,
        last_seen_at INT NULL,
        protocol_version INT NOT NULL DEFAULT 1,
        server_version TEXT NULL,
        auth_json TEXT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS scoped_server_links (
        id TEXT PRIMARY KEY NOT NULL,
        scope TEXT NOT NULL,
        server_id TEXT NOT NULL,
        sync_enabled INT NOT NULL DEFAULT 1,
        linked_at INT NOT NULL,
        FOREIGN KEY(server_id) REFERENCES sync_servers(id) ON DELETE CASCADE
      )
    ''');
  }
}
