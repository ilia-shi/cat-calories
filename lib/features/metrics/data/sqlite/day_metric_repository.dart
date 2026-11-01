import 'package:cat_calories/database/database_client.dart';
import 'package:cat_calories_core/features/metrics/domain/day_metric_entry.dart';
import 'package:cat_calories_core/features/metrics/domain/day_metric_repository_interface.dart';
import 'package:cat_calories_core/features/profile/domain/profile.dart';

class DayMetricRepository implements DayMetricRepositoryInterface {
  static const String tableName = 'day_metric_entries';
  final DatabaseClient _db;

  DayMetricRepository(this._db);

  @override
  Future<List<DayMetricEntry>> findAll() async {
    final result = await _db.query(tableName, orderBy: 'day DESC');

    return result.map(DayMetricEntry.fromJson).toList();
  }

  @override
  Future<List<DayMetricEntry>> fetchByProfile(Profile profile) async {
    final result = await _db.query(tableName,
        where: 'profile_id = ? AND deleted_at IS NULL',
        whereArgs: [profile.id],
        orderBy: 'day DESC');

    return result.map(DayMetricEntry.fromJson).toList();
  }

  @override
  Future<DayMetricEntry?> find(String id) async {
    final result =
        await _db.query(tableName, where: 'id = ?', whereArgs: [id], limit: 1);
    if (result.isEmpty) {
      return null;
    }

    return DayMetricEntry.fromJson(result.first);
  }

  @override
  Future<void> save(DayMetricEntry entry) async {
    final existing = await find(entry.id);
    if (existing == null) {
      await _db.insert(tableName, entry.toJson());
      return;
    }

    final row = entry.toJson()
      ..['created_at'] = existing.createdAt.millisecondsSinceEpoch;
    await _db.update(tableName, row, where: 'id = ?', whereArgs: [entry.id]);
  }

  @override
  Future<void> delete(DayMetricEntry entry) {
    return save(entry.markedDeleted(DateTime.now()));
  }

  @override
  Future<void> purge(String id) async {
    await _db.delete(tableName, where: 'id = ?', whereArgs: [id]);
  }
}
