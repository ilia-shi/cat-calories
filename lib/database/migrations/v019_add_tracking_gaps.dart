import 'package:sqflite/sqflite.dart';
import 'package:cat_calories/database/migrations/migration.dart';

class V019AddTrackingGaps extends Migration {
  @override
  int get version => 19;

  @override
  Future<void> up(Database db) async {
    await db.execute('''
      CREATE TABLE tracking_gaps(
        id TEXT PRIMARY KEY NOT NULL,
        profile_id TEXT NOT NULL,
        started_at INT NOT NULL,
        ended_at INT NOT NULL,
        description TEXT NULL,
        created_at INT NOT NULL,
        updated_at INT NOT NULL,
        deleted_at INT NULL,
        FOREIGN KEY(profile_id) REFERENCES profiles(id)
      )
    ''');
    await db.execute(
        'CREATE INDEX tracking_gaps_profile_started_idx '
        'ON tracking_gaps(profile_id, started_at)');
  }
}
