import 'package:cat_calories/database/migrations/abstract_migration.dart';
import 'package:sqflite/sqflite.dart';

class MigrationExecutor {
  static final List<AbstractMigration> _migrations = [

  ];

  Future<void> upgrade(Database db, int oldVersion, int newVersion) async {
    final Batch batch = db.batch();
    await _createMigrationsTable(batch);
    final List<int> list = [
      for (var i = oldVersion + 1; i <= newVersion; i += 1) i
    ];

    list.forEach((int version) async {
      _migrations.forEach((AbstractMigration migration) async {
        if (migration.getVersion() == version) {
          print('\x1B[32mUp to version $version...\x1B[0m');

          final Batch batchToExecute = await migration.up(batch);
          batchToExecute.commit();

          print('\x1B[32mUp to version $version success!\x1B[0m');
        }
      });
    });
  }

  Future<void> downgrade(Database db, int oldVersion, int newVersion) async {
    final Batch batch = db.batch();
    await _createMigrationsTable(batch);
    final List<int> list = [
      for (var i = newVersion + 1; i <= oldVersion; i += 1) i
    ].reversed.toList();

    list.forEach((int version) async {
      _migrations.forEach((AbstractMigration migration) async {
        if (migration.getVersion() == version) {
          print('\x1B[32mDown to version $version...\x1B[0m');

          final Batch batchToExecute = await migration.down(batch);
          batchToExecute.commit();

          print('\x1B[32mDown to version $version success!\x1B[0m');
        }
      });
    });
  }

  Future<List> _createMigrationsTable(Batch batch) async {
    batch.execute('''
				CREATE TABLE IF NOT EXISTS migration_versions (
					version INT UNIQUE,
					executed_at INT NOT NULL
				)
			''');
    return await batch.commit();
  }

  int getLastMigrationVersion() {
    int lastVersion = 2;

    return lastVersion;
  }

  Future<int> getExecutedMigrationVersion(Database db) async {
    await _createMigrationsTable(db.batch());

    final result = await db.rawQuery('''
      SELECT *
      FROM migration_versions
      LIMIT 1
    ''');

    print(result);

    return 1;
  }
}
