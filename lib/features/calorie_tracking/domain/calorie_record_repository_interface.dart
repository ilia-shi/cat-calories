import 'package:cat_calories/features/calorie_tracking/domain/calorie_record.dart';
import 'package:cat_calories/features/calorie_tracking/domain/day_result.dart';
import 'package:cat_calories/features/profile/domain/profile_model.dart';
import 'package:cat_calories/features/waking_periods/domain/waking_period_model.dart';

abstract interface class CalorieRecordRepositoryInterface {
  Future<List<CalorieRecord>> findAll();
  Future<List<CalorieRecord>> fetchAllByProfile(ProfileModel profile,
      {String orderBy, int? limit, int? offset});
  Future<List<CalorieRecord>> fetchAllByProfileAndDay(ProfileModel profile,
      {String orderBy, int? limit, int? offset, required DateTime dayStart});
  Future<List<CalorieRecord>> fetchByCreatedAtDay(DateTime createdAtDay);
  Future<void> deleteByCreatedAtDay(
      DateTime createdAtDay, ProfileModel profile);
  Future<List<CalorieRecord>> fetchByWakingPeriodAndProfile(
      WakingPeriodModel wakingPeriod, ProfileModel profile);
  Future<CalorieRecord?> find(String id);
  Future<List<DayResultModel>> fetchDaysByProfile(
      ProfileModel profile, int limit);
  Future<CalorieRecord> insert(CalorieRecord calorieItem);
  Future<void> offsetSortOrder();
  Future<CalorieRecord> update(CalorieRecord calorieItem);
  Future<int> delete(CalorieRecord calorieItem);
  Future<int> deleteAll();
  Future resort(List<CalorieRecord> items);
}
