import 'package:cat_calories_core/features/metrics/domain/day_metric.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// What the calendar shows: a metric, or food when null. Lives above the
/// navigator for the same reasons as CalendarModeCubit.
class CalendarContentCubit extends Cubit<DayMetric?> {
  CalendarContentCubit() : super(null);

  void select(DayMetric? metric) => emit(metric);
}
