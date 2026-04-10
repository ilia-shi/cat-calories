import 'package:sqflite/sqflite.dart';

abstract class Migration {
  int get version;

  Future<void> up(Database db);

  Future<bool> columnExists(Database db, String table, String column) async {
    final result = await db.rawQuery('PRAGMA table_info($table)');
    return result.any((row) => row['name'] == column);
  }

  Future<void> addColumnIfNotExists(
      Database db, String table, String column, String type) async {
    if (!await columnExists(db, table, column)) {
      await db.execute('ALTER TABLE $table ADD COLUMN $column $type');
    }
  }

  Future<bool> tableExists(Database db, String tableName) async {
    final result = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
      [tableName],
    );
    return result.isNotEmpty;
  }
}
