import 'package:cat_calories_core/features/calorie_tracking/domain/record_day.dart';
import 'package:cat_calories_core/features/metrics/domain/day_metric.dart';
import 'package:uuid/uuid.dart';

const String manualMetricSource = 'manual';

const int _maxSleepMinutes = 24 * 60;
const String _idNamespace = '5f0d7a52-3c1e-4e0b-9a55-6b2f4c8d1e77';

/// One value of one metric on one calendar day, from one source.
final class DayMetricEntry {
  /// Derived from the other key fields by [dayMetricEntryId].
  final String id;
  final String profileId;
  final String metricKey;

  /// A calendar date as `YYYY-MM-DD`. Unlike `record_day`, which is built from
  /// local midnight in milliseconds, it does not change with the time zone, and
  /// [id] depends on it.
  final String day;
  final double value;
  final String source;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// A soft delete, because Syncer never pushes a deletion from the phone.
  final DateTime? deletedAt;

  const DayMetricEntry({
    required this.id,
    required this.profileId,
    required this.metricKey,
    required this.day,
    required this.value,
    required this.source,
    required this.note,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory DayMetricEntry.manual({
    required String profileId,
    required DayMetric metric,
    required DateTime day,
    required double value,
    required String? note,
    required DateTime now,
  }) {
    final dayKey = dayMetricKey(day);

    return DayMetricEntry(
      id: dayMetricEntryId(
        profileId: profileId,
        metricKey: metric.key,
        day: dayKey,
        source: manualMetricSource,
      ),
      profileId: profileId,
      metricKey: metric.key,
      day: dayKey,
      value: value,
      source: manualMetricSource,
      note: note,
      createdAt: now,
      updatedAt: now,
    );
  }

  factory DayMetricEntry.fromJson(Map<String, dynamic> json) => DayMetricEntry(
        id: json['id'],
        profileId: json['profile_id']?.toString() ?? '',
        metricKey: json['metric_key'],
        day: json['day'],
        value: (json['value'] as num).toDouble(),
        source: json['source'],
        note: json['note'],
        createdAt: DateTime.fromMillisecondsSinceEpoch(json['created_at']),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(json['updated_at']),
        deletedAt: json['deleted_at'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(json['deleted_at']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'profile_id': profileId,
        'metric_key': metricKey,
        'day': day,
        'value': value,
        'source': source,
        'note': note,
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
        'deleted_at': deletedAt?.millisecondsSinceEpoch,
      };

  /// Null for a metric this app version does not know.
  DayMetric? get metric => DayMetric.fromKey(metricKey);

  bool get isDeleted => deletedAt != null;

  DayMetricEntry markedDeleted(DateTime now) => DayMetricEntry(
        id: id,
        profileId: profileId,
        metricKey: metricKey,
        day: day,
        value: value,
        source: source,
        note: note,
        createdAt: createdAt,
        updatedAt: now,
        deletedAt: now,
      );
}

/// Deterministic, so two phones writing the same metric and day update one
/// entity through sync instead of leaving two rows for that day.
String dayMetricEntryId({
  required String profileId,
  required String metricKey,
  required String day,
  required String source,
}) {
  return const Uuid().v5(_idNamespace, '$profileId|$metricKey|$day|$source');
}

String dayMetricKey(DateTime moment) {
  final year = moment.year.toString().padLeft(4, '0');
  final month = moment.month.toString().padLeft(2, '0');
  final day = moment.day.toString().padLeft(2, '0');

  return '$year-$month-$day';
}

/// Local midnight of a `YYYY-MM-DD` key.
DateTime dayFromMetricKey(String key) => DateTime.parse(key);

/// Why [stored] cannot be saved for [day], or null when it can. Checked on save
/// only: a pulled entry is already a fact.
String? dayMetricError(
  DayMetric metric,
  double stored,
  DateTime day,
  DateTime now,
) {
  if (dayOf(day).isAfter(dayOf(now))) {
    return 'A value cannot be for a future day';
  }
  if (stored < 0) {
    return 'The value cannot be negative';
  }
  if (metric == DayMetric.sleepMinutes && stored > _maxSleepMinutes) {
    return 'Sleep cannot be over 24 hours';
  }

  return null;
}
