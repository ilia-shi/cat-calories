import 'package:cat_calories/database/database_client.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Drives the real repository against an in-memory database, so the day queries
/// are exercised as SQL rather than through a hand-written fake.
class TestDatabaseClient implements DatabaseClient {
  final Database db;

  TestDatabaseClient(this.db);

  @override
  Future<int> insert(String table, Map<String, dynamic> row) =>
      db.insert(table, row);

  @override
  Future<List<Map<String, dynamic>>> rawQuery(String sql,
          [List<dynamic>? arguments]) =>
      db.rawQuery(sql, arguments);

  @override
  Future<int> delete(String table, {String? where, List<dynamic>? whereArgs}) =>
      db.delete(table, where: where, whereArgs: whereArgs);

  @override
  Future<int> update(String table, Map<String, dynamic> values,
          {required String where, List<dynamic>? whereArgs}) =>
      db.update(table, values, where: where, whereArgs: whereArgs);

  @override
  Future<Batch> batch() async => db.batch();

  @override
  Future<List<Map<String, dynamic>>> query(String table,
          {String? where,
          List<dynamic>? whereArgs,
          String? groupBy,
          String? having,
          String? orderBy,
          int? limit,
          int? offset}) =>
      db.query(table,
          where: where,
          whereArgs: whereArgs,
          groupBy: groupBy,
          having: having,
          orderBy: orderBy,
          limit: limit,
          offset: offset);
}
