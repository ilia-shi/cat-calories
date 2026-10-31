import 'package:cat_calories_core/features/calorie_tracking/domain/day_result.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/record_day.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/tracking_gap.dart';

enum DayStatus {
  tracked,
  empty,
  partial,
  unknown;

  /// Whether the day enters averages. An `empty` day counts as 0 kcal on
  /// purpose: it stays highlighted until the user says it was not tracked.
  bool get isCounted => this == tracked || this == empty;
}

final class DayStat {
  final DateTime day;
  final DayStatus status;

  /// Null when the day has no records.
  final DayResult? result;

  const DayStat({required this.day, required this.status, this.result});

  double get kcal => result?.valueSum ?? 0;

  String get displayKcal => switch (status) {
        DayStatus.tracked => '${kcal.round()}',
        DayStatus.empty => '0',
        DayStatus.partial => '≥ ${kcal.round()}',
        DayStatus.unknown => '—',
      };
}

/// The next calendar day, built from calendar fields so a DST switch cannot
/// shift it off midnight.
DateTime nextDay(DateTime day) => DateTime(day.year, day.month, day.day + 1);

/// One entry per calendar day from [from] up to, not including, [to], oldest
/// first. Days before [firstRecordDay] are left out, so the time before the user
/// started logging is neither counted nor highlighted; with a null
/// [firstRecordDay] there is nothing to report.
///
/// [days] must reach back to [from]. Rows that land on the same local day, as
/// after a time zone change, are merged.
List<DayStat> dayStats({
  required List<DayResult> days,
  required List<TrackingGap> gaps,
  required DateTime? firstRecordDay,
  required DateTime from,
  required DateTime to,
}) {
  if (firstRecordDay == null) {
    return const [];
  }

  final results = <DateTime, DayResult>{};
  for (final result in days) {
    final key = dayOf(result.day);
    final existing = results[key];
    results[key] = existing == null ? result : _merge(key, existing, result);
  }

  final first = dayOf(firstRecordDay);
  final end = dayOf(to);
  final stats = <DayStat>[];

  for (var day = first.isAfter(dayOf(from)) ? first : dayOf(from);
      day.isBefore(end);
      day = nextDay(day)) {
    final result = results[day];
    final hasGap = gapOverlaps(gaps, day, nextDay(day));

    stats.add(DayStat(
      day: day,
      result: result,
      status: result == null
          ? (hasGap ? DayStatus.unknown : DayStatus.empty)
          : (hasGap ? DayStatus.partial : DayStatus.tracked),
    ));
  }

  return stats;
}

DayResult _merge(DateTime day, DayResult a, DayResult b) => DayResult(
      valueSum: a.valueSum + b.valueSum,
      positiveValueSum: a.positiveValueSum + b.positiveValueSum,
      negativeValueSum: a.negativeValueSum + b.negativeValueSum,
      day: day,
    );

/// The days a calorie recommendation may learn from. Unlike statistics it skips
/// `empty` days, which never reach it because they have no row: at a 2000 kcal
/// goal one forgotten day would read as a -2000 kcal deviation.
List<DayResult> trackedDays(List<DayResult> days, List<TrackingGap> gaps) {
  return days.where((result) {
    final day = dayOf(result.day);

    return !gapOverlaps(gaps, day, nextDay(day));
  }).toList();
}
