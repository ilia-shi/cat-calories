import 'package:sqflite/sqflite.dart';
import 'package:cat_calories/database/migrations/migration.dart';

class V020AddDayMetrics extends Migration {
  @override
  int get version => 20;

  @override
  Future<void> up(Database db) async {
    await db.execute('''
      CREATE TABLE day_metric_entries(
        id TEXT PRIMARY KEY NOT NULL,
        profile_id TEXT NOT NULL,
        metric_key TEXT NOT NULL,
        day TEXT NOT NULL,
        value REAL NOT NULL,
        source TEXT NOT NULL,
        note TEXT NULL,
        created_at INT NOT NULL,
        updated_at INT NOT NULL,
        deleted_at INT NULL,
        FOREIGN KEY(profile_id) REFERENCES profiles(id)
      )
    ''');
    await db.execute(
        'CREATE INDEX day_metric_entries_profile_day_idx '
        'ON day_metric_entries(profile_id, day)');
  }
}
