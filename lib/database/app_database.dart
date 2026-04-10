import 'dart:io';
import 'package:cat_calories/database/database_client.dart';
import 'package:cat_calories/database/migration_runner.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase implements DatabaseClient {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  Database? _database;

  Future<Database?> get database async {
    if (_database != null) return _database;
    _database = await _initDb();
    return _database;
  }

  Future<Database> _initDb() async {
    print('[BOOT] AppDatabase._initDb - start');
    Directory documentsDir = await getApplicationDocumentsDirectory();
    String path = join(documentsDir.path, 'app.db');
    print('[BOOT] AppDatabase._initDb - path: $path');

    final runner = MigrationRunner();

    final db = await openDatabase(
      path,
      version: MigrationRunner.currentVersion,
      onCreate: runner.onCreate,
      onUpgrade: runner.onUpgrade,
      onDowngrade: runner.onDowngrade,
    );
    print('[BOOT] AppDatabase._initDb - database opened');
    return db;
  }

  Future<Database> getDatabase() async {
    Database? db = await database;
    if (db == null) {
      throw Exception('No DB connection.');
    }
    return db;
  }

  @override
  Future<int> insert(String table, Map<String, dynamic> row) async {
    Database db = await getDatabase();
    return await db.insert(table, row);
  }

  @override
  Future<List<Map<String, dynamic>>> rawQuery(String sql,
      [List<dynamic>? arguments]) async {
    final Database db = await getDatabase();
    return await db.rawQuery(sql, arguments);
  }

  @override
  Future<int> delete(String table,
      {String? where, List<dynamic>? whereArgs}) async {
    final Database db = await getDatabase();
    return db.delete(table, where: where, whereArgs: whereArgs);
  }

  @override
  Future<int> update(String table, Map<String, dynamic> values,
      {required String where, List<dynamic>? whereArgs}) async {
    final Database db = await getDatabase();
    return db.update(table, values, where: where, whereArgs: whereArgs);
  }

  @override
  Future<Batch> batch() async {
    final Database db = await getDatabase();
    return db.batch();
  }

  @override
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
