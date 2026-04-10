import 'package:cat_calories_core/features/profile/domain/profile.dart';
import 'package:cat_calories_core/features/waking_periods/domain/waking_period.dart';

abstract interface class WakingPeriodRepositoryInterface {
  Future<List<WakingPeriod>> fetchAll();
  Future<List<WakingPeriod>> fetchByProfile(Profile profile);
  Future<WakingPeriod> insert(WakingPeriod wakingPeriod);
  Future<int> delete(WakingPeriod wakingPeriod);
  Future<WakingPeriod?> findActual(Profile profile);
  Future<int> deleteAll();
  Future<WakingPeriod> update(WakingPeriod wakingPeriod);
  Future<WakingPeriod?> findFirstFromStartDate(
      Profile profile, DateTime dateTime);
}
