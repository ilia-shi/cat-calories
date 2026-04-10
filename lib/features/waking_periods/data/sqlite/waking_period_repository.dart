import 'package:cat_calories/database/database_client.dart';
import 'package:cat_calories_core/features/profile/domain/profile.dart';
import 'package:cat_calories_core/features/waking_periods/domain/waking_period.dart';
import 'package:cat_calories_core/features/waking_periods/domain/waking_period_repository_interface.dart';
import 'package:uuid/uuid.dart';

class WakingPeriodRepository implements WakingPeriodRepositoryInterface {
  static const _uuid = Uuid();
  final DatabaseClient _db;

  WakingPeriodRepository(this._db);
  Future<List<WakingPeriod>> fetchAll() async {
    final wakingPeriodsResult = await _db.query('waking_periods');

    return wakingPeriodsResult
        .map((element) => WakingPeriod.fromJson(element))
        .toList();
  }

  Future<List<WakingPeriod>> fetchByProfile(Profile profile) async {
    final wakingPeriodsResult = await _db.query('waking_periods', where: 'profile_id = ?', whereArgs: [profile.id!], orderBy: 'id DESC');

    return wakingPeriodsResult
        .map((element) => WakingPeriod.fromJson(element))
        .toList();
  }

  Future<WakingPeriod> insert(WakingPeriod wakingPeriod) async {
    if (wakingPeriod.id == null) {
      wakingPeriod.id = _uuid.v4();
    }
    await _db.insert('waking_periods', wakingPeriod.toJson());

    return wakingPeriod;
  }

  Future<int> delete(WakingPeriod wakingPeriod) async {
    return await _db
        .delete('waking_periods', where: 'id = ?', whereArgs: [wakingPeriod.id]);
  }

  Future<WakingPeriod?> findActual(Profile profile) async {
    final wakingPeriodsResult = await _db.rawQuery('SELECT * FROM waking_periods WHERE ended_at IS NULL AND profile_id = ?', [profile.id]);

    if (wakingPeriodsResult.toList().length == 0) {
      return null;
    }

    return WakingPeriod.fromJson(wakingPeriodsResult.toList().first);
  }

  Future<int> deleteAll() async {
    return await _db.delete('waking_periods');
  }

  Future<WakingPeriod> update(WakingPeriod wakingPeriod) async {
    await _db.update('waking_periods', wakingPeriod.toJson(),
        where: 'id = ?', whereArgs: [wakingPeriod.id]);

    return wakingPeriod;
  }

  Future<WakingPeriod?> findFirstFromStartDate(Profile profile, DateTime dateTime) async {
    final wakingPeriodsResult = await _db.rawQuery('SELECT *  FROM waking_periods  WHERE ended_at IS NULL  AND profile_id = ? LIMIT 1', [profile.id]);

    if (wakingPeriodsResult.toList().length == 0) {
      return null;
    }

    return WakingPeriod.fromJson(wakingPeriodsResult.toList().first);
  }
}
