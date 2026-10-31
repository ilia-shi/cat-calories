import 'package:cat_calories_core/features/calorie_tracking/domain/calendar_cells.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Lives above the navigator: the tracking tab rebuilds its tree while loading,
/// and the full-screen calendar shares the mode. Lasts until the app is closed.
class CalendarModeCubit extends Cubit<CalendarMode> {
  CalendarModeCubit() : super(CalendarMode.weeks);

  void select(CalendarMode mode) => emit(mode);
}
