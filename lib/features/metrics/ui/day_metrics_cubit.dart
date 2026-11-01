import 'package:cat_calories_core/features/calorie_tracking/domain/record_day.dart';
import 'package:cat_calories_core/features/metrics/domain/day_metric.dart';
import 'package:cat_calories_core/features/metrics/domain/day_metric_entry.dart';
import 'package:cat_calories_core/features/metrics/domain/day_metric_repository_interface.dart';
import 'package:cat_calories_core/features/profile/domain/profile.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

const int _defaultDaysBack = 30;

final class DayMetricsState {
  final bool isLoading;

  /// Calendar days to list, newest first.
  final List<DateTime> days;
  final Map<(String, DayMetric), DayMetricEntry> _entries;

  const DayMetricsState({
    required this.isLoading,
    required this.days,
    required Map<(String, DayMetric), DayMetricEntry> entries,
  }) : _entries = entries;

  const DayMetricsState.loading()
      : isLoading = true,
        days = const [],
        _entries = const {};

  DayMetricEntry? entryFor(DateTime day, DayMetric metric) {
    return _entries[(dayMetricKey(day), metric)];
  }
}

class DayMetricsCubit extends Cubit<DayMetricsState> {
  final DayMetricRepositoryInterface _repository;
  final Profile _profile;
  final DateTime Function() _now;
  DateTime? _pickedDay;

  /// Whether a value was saved or cleared since the cubit was created.
  bool hasChanges = false;

  DayMetricsCubit(
    this._repository,
    this._profile, {
    DateTime Function()? now,
  })  : _now = now ?? DateTime.now,
        super(const DayMetricsState.loading());

  Future<void> load() async {
    final loaded = await _repository.fetchByProfile(_profile);
    final known = loaded.where((entry) => entry.metric != null);
    final today = dayOf(_now());

    var oldest = DateTime(today.year, today.month, today.day - _defaultDaysBack);
    for (final entry in known) {
      final day = dayFromMetricKey(entry.day);
      if (day.isBefore(oldest)) {
        oldest = day;
      }
    }
    final picked = _pickedDay;
    if (picked != null && picked.isBefore(oldest)) {
      oldest = picked;
    }

    final days = <DateTime>[];
    // Built from calendar fields: a DST switch would knock a Duration off midnight.
    for (var day = today;
        !day.isBefore(oldest);
        day = DateTime(day.year, day.month, day.day - 1)) {
      days.add(day);
    }

    emit(DayMetricsState(
      isLoading: false,
      days: days,
      entries: {
        for (final entry in known) (entry.day, entry.metric!): entry,
      },
    ));
  }

  Future<void> save(
    DayMetric metric,
    DateTime day,
    double value,
    String? note,
  ) async {
    await _repository.save(DayMetricEntry.manual(
      profileId: _profile.id!,
      metric: metric,
      day: day,
      value: value,
      note: note,
      now: _now(),
    ));
    hasChanges = true;
    await load();
  }

  Future<void> clear(DayMetricEntry entry) async {
    await _repository.delete(entry);
    hasChanges = true;
    await load();
  }

  Future<void> showFrom(DateTime day) async {
    _pickedDay = dayOf(day);
    await load();
  }
}
