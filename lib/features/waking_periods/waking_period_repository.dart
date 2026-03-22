import 'package:cat_calories/database/database_client.dart';
import 'package:cat_calories/features/profile/domain/profile_model.dart';
import 'package:cat_calories/features/waking_periods/domain/waking_period_model.dart';

class WakingPeriodRepository {
  final DatabaseClient _db;

  WakingPeriodRepository(this._db);
  Future<List<WakingPeriodModel>> fetchAll() async {
    final wakingPeriodsResult = await _db.query('waking_periods');

    return wakingPeriodsResult
        .map((element) => WakingPeriodModel.fromJson(element))
        .toList();
  }

  Future<List<WakingPeriodModel>> fetchByProfile(ProfileModel profile) async {
    final wakingPeriodsResult = await _db.query('waking_periods', where: 'profile_id = ?', whereArgs: [profile.id!], orderBy: 'id DESC');

    return wakingPeriodsResult
        .map((element) => WakingPeriodModel.fromJson(element))
        .toList();
  }

  Future<WakingPeriodModel> insert(WakingPeriodModel wakingPeriod) async {
    wakingPeriod.id = await _db.insert('waking_periods', wakingPeriod.toJson());

    return wakingPeriod;
  }

  Future<int> delete(WakingPeriodModel wakingPeriod) async {
    return await _db
        .delete('waking_periods', where: 'id = ?', whereArgs: [wakingPeriod.id]);
  }

  Future<WakingPeriodModel?> findActual(ProfileModel profile) async {
    final wakingPeriodsResult = await _db.rawQuery('SELECT * FROM waking_periods WHERE ended_at IS NULL AND profile_id = ?', [profile.id]);

    if (wakingPeriodsResult.toList().length == 0) {
      return null;
    }

    return WakingPeriodModel.fromJson(wakingPeriodsResult.toList().first);
  }

  Future<int> deleteAll() async {
    return await _db.delete('waking_periods');
  }

  Future<WakingPeriodModel> update(WakingPeriodModel wakingPeriod) async {
    await _db.update('waking_periods', wakingPeriod.toJson(),
        where: 'id = ?', whereArgs: [wakingPeriod.id]);

    return wakingPeriod;
  }

  Future<WakingPeriodModel?> findFirstFromStartDate(ProfileModel profile, DateTime dateTime) async {
    final wakingPeriodsResult = await _db.rawQuery('SELECT *  FROM waking_periods  WHERE ended_at IS NULL  AND profile_id = ? LIMIT 1', [profile.id]);

    if (wakingPeriodsResult.toList().length == 0) {
      return null;
    }

    return WakingPeriodModel.fromJson(wakingPeriodsResult.toList().first);
  }
}
