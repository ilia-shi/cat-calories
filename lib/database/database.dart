import 'dart:io';
import 'dart:async';
import 'package:cat_calories/database/migration_executor.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DBProvider {
  DBProvider._();

  static final DBProvider db = DBProvider._();

  Database? _database;

  Future<Database?> get database async {
    if (_database != null) {
      return _database;
    }

    _database = await initDB();

    return _database;
  }

  Future<bool> _columnExists(Database db, String table, String column) async {
    final result = await db.rawQuery('PRAGMA table_info($table)');
    return result.any((row) => row['name'] == column);
  }

  Future<void> _addColumnIfNotExists(Database db, String table, String column, String type) async {
    if (!await _columnExists(db, table, column)) {
      print('Adding column $column to $table...');
      await db.execute('ALTER TABLE $table ADD COLUMN $column $type');
    }
  }

  Future<void> _ensureColumns(Database db) async {
    await _addColumnIfNotExists(db, 'calorie_items', 'weight_grams', 'REAL NULL');
    await _addColumnIfNotExists(db, 'calorie_items', 'protein_grams', 'REAL NULL');
    await _addColumnIfNotExists(db, 'calorie_items', 'fat_grams', 'REAL NULL');
    await _addColumnIfNotExists(db, 'calorie_items', 'carb_grams', 'REAL NULL');
  }

  initDB() async {
    Directory documentsDir = await getApplicationDocumentsDirectory();
    String path = join(documentsDir.path, 'app.db');

    // For development: delete existing database to force recreation
    // Remove this in production!
    // final file = File(path);
    // if (await file.exists()) {
    //   await file.delete();
    // }

    return await openDatabase(
      path,
      version: 3,
      onOpen: (db) async {
        await _ensureColumns(db);
      },
      onCreate: (Database db, int version) async {
        print('Creating database tables...');

        await db.execute('''
          CREATE TABLE profiles(
            id INTEGER PRIMARY KEY NOT NULL,
            name TEXT,
            created_at INT,
            updated_at INT,
            waking_time_seconds INT,
            calories_limit_goal REAL
          )
        ''');

        await db.execute('''
          CREATE TABLE waking_periods (
            id INTEGER PRIMARY KEY NOT NULL,
            description TEXT NULL,
            created_at INT,
            updated_at INT,
            started_at INT,
            ended_at INT NULL,
            calories_value REAL,
            profile_id INT,
            expected_waking_time_seconds INT,
            calories_limit_goal REAL,
            FOREIGN KEY(profile_id) REFERENCES profiles(id)
          )
        ''');

        await db.execute('''
          CREATE TABLE calorie_items (
            id INTEGER PRIMARY KEY NOT NULL,
            value REAL,
            title TEXT NULL,
            description TEXT NULL,
            sort_order INT,
            created_at INT,
            created_at_day INT,
            eaten_at INT NULL,
            profile_id INT,
            waking_period_id INT,
            weight_grams REAL NULL,
            protein_grams REAL NULL,
            fat_grams REAL NULL,
            carb_grams REAL NULL,
            FOREIGN KEY(profile_id) REFERENCES profiles(id),
            FOREIGN KEY(waking_period_id) REFERENCES waking_periods(id)
          )
        ''');

        await db.execute('''
          CREATE TABLE products(
            id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
            title TEXT,
            description TEXT NULL,
            created_at INT,
            updated_at INT,
            uses_count INT,
            profile_id INT,
            sort_order INT DEFAULT 0,
            barcode INT NULL,
            calorie_content REAL NULL,
            proteins REAL NULL,
            fats REAL NULL,
            carbohydrates REAL NULL,
            FOREIGN KEY(profile_id) REFERENCES profiles(id)
          )
        ''');

        await db.execute('''
          CREATE INDEX calorie_items_created_at_day_idx ON calorie_items(created_at_day)
        ''');

        print('Database tables created successfully!');
      },
      onUpgrade: MigrationExecutor().upgrade,
      onDowngrade: MigrationExecutor().downgrade,
    );
  }

  Future<Database> getDatabase() async {
    Database? db = await database;

    if (db == null) {
      throw Exception('No DB connection.');
    }

    return db;
  }

  Future<int> insert(String table, Map<String, dynamic> row) async {
    Database db = await getDatabase();
    return await db.insert(table, row);
  }

  Future<List<Map<String, dynamic>>> rawQuery(String sql,
      [List<dynamic>? arguments]) async {
    final Database db = await getDatabase();
    return await db.rawQuery(sql, arguments);
  }

  Future<int> delete(String table,
      {String? where, List<dynamic>? whereArgs}) async {
    final Database db = await getDatabase();
    return db.delete(table, where: where, whereArgs: whereArgs);
  }

  Future<int> update(String table, Map<String, dynamic> values,
      {required String where, List<dynamic>? whereArgs}) async {
    final Database db = await getDatabase();
    return db.update(table, values, where: where, whereArgs: whereArgs);
  }

  Future<Batch> batch() async {
    final Database db = await getDatabase();
    Batch batch = db.batch();
    return batch;
  }

  Future<List<Map<String, dynamic>>> query(String table,
      {String? where,
        List<dynamic>? whereArgs,
        String? groupBy,
        String? having,
        String? orderBy,
        int? limit,
        int? offset}) async {
    final db = await getDatabase();
    return db.query(table,
        where: where,
        whereArgs: whereArgs,
        orderBy: orderBy,
        limit: limit,
        offset: offset,
        groupBy: groupBy);
  }
}