import 'package:sqflite/sqflite.dart';
import 'package:cat_calories/database/migrations/migration.dart';

class V012AddServerUrls extends Migration {
  @override
  int get version => 12;

  @override
  Future<void> up(Database db) async {
    await addColumnIfNotExists(
        db, 'sync_servers', 'server_urls', "TEXT NOT NULL DEFAULT '[]'");

    await db.execute('''
      UPDATE sync_servers
      SET server_urls = '["' || server_url || '"]'
      WHERE server_url IS NOT NULL AND server_url != ''
    ''');
  }
}
