import 'package:cat_calories_core/features/calorie_tracking/domain/calorie_record.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/calorie_record_repository_interface.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/day_result.dart';
import 'package:cat_calories_core/features/profile/domain/profile.dart';
import 'package:cat_calories_core/features/waking_periods/domain/waking_period.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:uuid/uuid.dart';

class ServerCalorieRecordRepository implements CalorieRecordRepositoryInterface {
  final Database _db;

  ServerCalorieRecordRepository(this._db);

  @override
  Future<List<CalorieRecord>> findAll() async {
    final result = _db.select('SELECT * FROM calorie_items ORDER BY sort_order ASC');
    return result.map(_rowToRecord).toList();
  }

  @override
  Future<List<CalorieRecord>> fetchAllByProfile(Profile profile,
      {String orderBy = 'id ASC', int? limit, int? offset}) async {
    var sql = 'SELECT * FROM calorie_items WHERE profile_id = ? ORDER BY $orderBy';
    if (limit != null) sql += ' LIMIT $limit';
    if (offset != null) sql += ' OFFSET $offset';
    final result = _db.select(sql, [profile.id]);
    return result.map(_rowToRecord).toList();
  }

  @override
  Future<List<CalorieRecord>> fetchAllByProfileAndDay(Profile profile,
      {String orderBy = 'id ASC',
      int? limit,
      int? offset,
      required DateTime dayStart}) async {
    final dayTimestamp = (DateTime(dayStart.year, dayStart.month, dayStart.day)
                .millisecondsSinceEpoch /
            100000)
        .round();
    var sql =
        'SELECT * FROM calorie_items WHERE profile_id = ? AND created_at_day >= ? AND created_at_day <= ? ORDER BY $orderBy';
    if (limit != null) sql += ' LIMIT $limit';
    if (offset != null) sql += ' OFFSET $offset';
    final result = _db.select(sql, [profile.id, dayTimestamp, dayTimestamp]);
    return result.map(_rowToRecord).toList();
  }

  @override
  Future<List<CalorieRecord>> fetchByCreatedAtDay(DateTime createdAtDay) async {
    final dayTimestamp =
        (DateTime(createdAtDay.year, createdAtDay.month, createdAtDay.day)
                    .millisecondsSinceEpoch /
                100000)
            .round();
    final result = _db.select(
      'SELECT * FROM calorie_items WHERE created_at_day = ?',
      [dayTimestamp],
    );
    return result.map(_rowToRecord).toList();
  }

  @override
  Future<void> deleteByCreatedAtDay(DateTime createdAtDay, Profile profile) async {
    final dayTimestamp =
        (DateTime(createdAtDay.year, createdAtDay.month, createdAtDay.day)
                    .millisecondsSinceEpoch /
                100000)
            .round();
    _db.execute(
      'DELETE FROM calorie_items WHERE created_at_day = ? AND profile_id = ?',
      [dayTimestamp, profile.id],
    );
  }

  @override
  Future<List<CalorieRecord>> fetchByWakingPeriodAndProfile(
      WakingPeriod wakingPeriod, Profile profile) async {
    final result = _db.select(
      'SELECT * FROM calorie_items WHERE waking_period_id = ? AND profile_id = ? ORDER BY sort_order ASC',
      [wakingPeriod.id, profile.id],
    );
    return result.map(_rowToRecord).toList();
  }

  @override
  Future<CalorieRecord?> find(String id) async {
    final result = _db.select('SELECT * FROM calorie_items WHERE id = ?', [id]);
    if (result.isEmpty) return null;
    return _rowToRecord(result.first);
  }

  @override
  Future<List<DayResult>> fetchDaysByProfile(Profile profile, int limit) async {
    final result = _db.select('''
      SELECT
        SUM(value) as value_sum,
        SUM(CASE WHEN value > 0 THEN value ELSE 0 END) positive_value_sum,
        SUM(CASE WHEN value < 0 THEN value ELSE 0 END) negative_value_sum,
        created_at_day
      FROM calorie_items
      WHERE profile_id = ?
      GROUP BY created_at_day
      ORDER BY created_at_day DESC
      LIMIT ?
    ''', [profile.id, limit]);
    return result
        .map((row) => DayResult.fromJson({
              'value_sum': row['value_sum'],
              'positive_value_sum': row['positive_value_sum'],
              'negative_value_sum': row['negative_value_sum'],
              'created_at_day': row['created_at_day'],
            }))
        .toList();
  }

  @override
  Future<CalorieRecord> insert(CalorieRecord item) async {
    item.id ??= const Uuid().v4();
    final json = item.toJson();
    _db.execute('''
      INSERT INTO calorie_items (
        id, profile_id, waking_period_id, product_id, value, description,
        sort_order, weight_grams, protein_grams, fat_grams, carb_grams,
        created_at_day, eaten_at, created_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''', [
      json['id'],
      json['profile_id'],
      json['waking_period_id'],
      json['product_id'],
      json['value'],
      json['description'],
      json['sort_order'],
      json['weight_grams'],
      json['protein_grams'],
      json['fat_grams'],
      json['carb_grams'],
      json['created_at_day'],
      json['eaten_at'],
      json['created_at'],
      json['updated_at'],
    ]);
    return item;
  }

  @override
  Future<void> offsetSortOrder() async {
    _db.execute('UPDATE calorie_items SET sort_order = sort_order + 1');
  }

  @override
  Future<CalorieRecord> update(CalorieRecord item) async {
    final json = item.toJson();
    _db.execute('''
      UPDATE calorie_items SET
        value = ?, description = ?, sort_order = ?,
        weight_grams = ?, protein_grams = ?, fat_grams = ?, carb_grams = ?,
        eaten_at = ?, updated_at = ?, product_id = ?, waking_period_id = ?
      WHERE id = ?
    ''', [
      json['value'],
      json['description'],
      json['sort_order'],
      json['weight_grams'],
      json['protein_grams'],
      json['fat_grams'],
      json['carb_grams'],
      json['eaten_at'],
      json['updated_at'],
      json['product_id'],
      json['waking_period_id'],
      json['id'],
    ]);
    return item;
  }

  @override
  Future<int> delete(CalorieRecord item) async {
    _db.execute('DELETE FROM calorie_items WHERE id = ?', [item.id]);
    return 1;
  }

  @override
  Future<int> deleteAll() async {
    _db.execute('DELETE FROM calorie_items');
    return _db.updatedRows;
  }

  @override
  Future resort(List<CalorieRecord> items) async {
    for (var i = 0; i < items.length; i++) {
      _db.execute(
        'UPDATE calorie_items SET sort_order = ? WHERE id = ?',
        [i, items[i].id],
      );
    }
  }

  CalorieRecord _rowToRecord(Row row) {
    return CalorieRecord.fromJson({
      'id': row['id'],
      'profile_id': row['profile_id'],
      'waking_period_id': row['waking_period_id'],
      'product_id': row['product_id'],
      'value': row['value'],
      'description': row['description'],
      'sort_order': row['sort_order'],
      'weight_grams': row['weight_grams'],
      'protein_grams': row['protein_grams'],
      'fat_grams': row['fat_grams'],
      'carb_grams': row['carb_grams'],
      'eaten_at': row['eaten_at'],
      'created_at': row['created_at'],
      'updated_at': row['updated_at'],
    });
  }
}
