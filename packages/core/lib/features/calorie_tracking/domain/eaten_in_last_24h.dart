import 'package:cat_calories_core/features/calorie_tracking/domain/calorie_record.dart';

/// The window matches `RollingCalorieTracker.consumedInLast24h`, so calories and
/// macros on the rolling card always cover the same records.
List<CalorieRecord> eatenInLast24h(List<CalorieRecord> records, DateTime asOf) {
  final windowStart = asOf.subtract(const Duration(hours: 24));

  return records.where((record) {
    final at = record.eatenAt;

    return at != null && at.isAfter(windowStart) && !at.isAfter(asOf);
  }).toList();
}
