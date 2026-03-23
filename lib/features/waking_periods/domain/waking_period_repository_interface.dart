import 'package:cat_calories/features/profile/domain/profile_model.dart';
import 'package:cat_calories/features/waking_periods/domain/waking_period_model.dart';

abstract interface class WakingPeriodRepositoryInterface {
  Future<List<WakingPeriodModel>> fetchAll();
  Future<List<WakingPeriodModel>> fetchByProfile(ProfileModel profile);
  Future<WakingPeriodModel> insert(WakingPeriodModel wakingPeriod);
  Future<int> delete(WakingPeriodModel wakingPeriod);
  Future<WakingPeriodModel?> findActual(ProfileModel profile);
  Future<int> deleteAll();
  Future<WakingPeriodModel> update(WakingPeriodModel wakingPeriod);
  Future<WakingPeriodModel?> findFirstFromStartDate(
      ProfileModel profile, DateTime dateTime);
}
