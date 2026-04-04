import 'package:sqflite/sqflite.dart';

class ForeignKeyUpdate {
  final String table;
  final String column;
  const ForeignKeyUpdate(this.table, this.column);
}

class UuidTableMigrator {
  static const _generateUuid = """lower(hex(randomblob(4)) || '-' || hex(randomblob(2)) || '-4' ||
          substr(hex(randomblob(2)),2) || '-' ||
          substr('89ab', abs(random()) % 4 + 1, 1) ||
          substr(hex(randomblob(2)),2) || '-' || hex(randomblob(6)))""";

  static Future<String> _newUuid(Database db) async {
    final result = await db.rawQuery('SELECT $_generateUuid as uuid');
    return result.first['uuid'] as String;
  }

  /// Returns true if the table's id column is already TEXT.
  static Future<bool> _isAlreadyText(Database db, String table) async {
    final info = await db.rawQuery('PRAGMA table_info($table)');
    for (final row in info) {
      if (row['name'] == 'id') {
        final type = (row['type'] as String?)?.toUpperCase() ?? '';
        return type.contains('TEXT');
      }
    }
    return false;
  }

  /// Migrate a table from INTEGER id to TEXT UUID.
  ///
  /// [createNewTableSql] must create `{table}_new` with the desired schema.
  /// [foreignKeyUpdates] lists tables/columns that reference this table's id
  /// and need to be updated with the new UUIDs.
  /// [postMigrationSql] runs after migration (e.g. CREATE INDEX).
  static Future<void> migrate(
    Database db, {
    required String table,
    required String createNewTableSql,
    List<ForeignKeyUpdate> foreignKeyUpdates = const [],
    List<String> postMigrationSql = const [],
  }) async {
    final exists = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
      [table],
    );
    if (exists.isEmpty) return;
    if (await _isAlreadyText(db, table)) return;

    final oldTableInfo = await db.rawQuery('PRAGMA table_info($table)');

    try {
      await db.execute('DROP TABLE IF EXISTS ${table}_new');
      await db.execute(createNewTableSql);

      final newTableInfo = await db.rawQuery('PRAGMA table_info(${table}_new)');
      final newColumns = newTableInfo.map((r) => r['name'] as String).toSet();

      if (foreignKeyUpdates.isEmpty) {
        // Bulk insert - no FK tracking needed
        final cols = oldTableInfo
            .map((r) => r['name'] as String)
            .where((c) => c != 'id' && newColumns.contains(c))
            .toList();
        final colList = cols.join(', ');

        await db.execute('''
          INSERT INTO ${table}_new (id, $colList)
          SELECT $_generateUuid, $colList FROM $table
        ''');
      } else {
        // Row-by-row with id mapping for FK updates
        final oldRows = await db.query(table);
        final idMapping = <String, String>{};

        for (final row in oldRows) {
          final oldId = row['id'].toString();
          final newId = await _newUuid(db);
          idMapping[oldId] = newId;

          final values = <String, dynamic>{'id': newId};
          for (final col in row.keys) {
            if (col != 'id' && newColumns.contains(col)) {
              values[col] = row[col];
            }
          }
          await db.insert('${table}_new', values);
        }

        // Update foreign keys in related tables
        for (final fk in foreignKeyUpdates) {
          for (final entry in idMapping.entries) {
            // Try integer match (SQLite may store FK as int)
            final oldInt = int.tryParse(entry.key);
            if (oldInt != null) {
              await db.execute(
                'UPDATE ${fk.table} SET ${fk.column} = ? WHERE ${fk.column} = ?',
                [entry.value, oldInt],
              );
            }
            // Try string match
            await db.execute(
              'UPDATE ${fk.table} SET ${fk.column} = ? WHERE ${fk.column} = ?',
              [entry.value, entry.key],
            );
          }
        }
      }

      await db.execute('DROP TABLE $table');
      await db.execute('ALTER TABLE ${table}_new RENAME TO $table');

      for (final sql in postMigrationSql) {
        await db.execute(sql);
      }
    } catch (e) {
      try {
        await db.execute('DROP TABLE IF EXISTS ${table}_new');
      } catch (_) {}
      rethrow;
    }
  }
}
