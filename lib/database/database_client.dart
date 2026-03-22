import 'package:sqflite/sqflite.dart';

abstract interface class DatabaseClient {
  Future<int> insert(String table, Map<String, dynamic> row);

  Future<List<Map<String, dynamic>>> rawQuery(String sql,
      [List<dynamic>? arguments]);

  Future<int> delete(String table,
      {String? where, List<dynamic>? whereArgs});

  Future<int> update(String table, Map<String, dynamic> values,
      {required String where, List<dynamic>? whereArgs});

  Future<Batch> batch();

  Future<List<Map<String, dynamic>>> query(String table,
      {String? where,
      List<dynamic>? whereArgs,
      String? groupBy,
      String? having,
      String? orderBy,
      int? limit,
      int? offset});
}
