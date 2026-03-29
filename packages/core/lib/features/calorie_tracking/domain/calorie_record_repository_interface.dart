import 'package:cat_calories_core/features/calorie_tracking/domain/calorie_record.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/day_result.dart';
import 'package:cat_calories_core/features/profile/domain/profile.dart';
import 'package:cat_calories_core/features/waking_periods/domain/waking_period.dart';

abstract interface class CalorieRecordRepositoryInterface {
  Future<List<CalorieRecord>> findAll();
  Future<List<CalorieRecord>> fetchAllByProfile(Profile profile,
      {String orderBy, int? limit, int? offset});
  Future<List<CalorieRecord>> fetchAllByProfileAndDay(Profile profile,
      {String orderBy, int? limit, int? offset, required DateTime dayStart});
  Future<List<CalorieRecord>> fetchByCreatedAtDay(DateTime createdAtDay);
  Future<void> deleteByCreatedAtDay(
      DateTime createdAtDay, Profile profile);
  Future<List<CalorieRecord>> fetchByWakingPeriodAndProfile(
      WakingPeriod wakingPeriod, Profile profile);
  Future<CalorieRecord?> find(String id);
  Future<List<DayResult>> fetchDaysByProfile(
      Profile profile, int limit);
  Future<CalorieRecord> insert(CalorieRecord calorieItem);
  Future<void> offsetSortOrder();
  Future<CalorieRecord> update(CalorieRecord calorieItem);
  Future<int> delete(CalorieRecord calorieItem);
  Future<int> deleteAll();
  Future resort(List<CalorieRecord> items);
}
