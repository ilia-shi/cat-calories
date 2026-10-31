import 'package:cat_calories/app/profile_resolver.dart';
import 'package:cat_calories/app/state/home_bloc.dart';
import 'package:cat_calories/app/state/home_state.dart';
import 'package:cat_calories/common/locator.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/calendar_cells.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/calorie_record_repository_interface.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/day_nutrition.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/tracking_gap.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/tracking_gap_repository_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

final class CalendarData {
  final String profileId;
  final double goal;
  final List<DayNutrition> nutrition;
  final List<TrackingGap> gaps;
  final Map<CalendarMode, List<CalendarCell>> _cells = {};

  CalendarData({
    required this.profileId,
    required this.goal,
    required this.nutrition,
    required this.gaps,
  });

  /// Cached per mode: the tracking tab rebuilds every 30 seconds, and building
  /// cells walks the whole history.
  List<CalendarCell> cells(CalendarMode mode) {
    return _cells[mode] ??= calendarCells(
      nutrition: nutrition,
      gaps: gaps,
      mode: mode,
      now: DateTime.now(),
    );
  }
}

/// Loads the calendar's data and reloads it on every [HomeFetched].
class CalendarDataBuilder extends StatefulWidget {
  final Widget Function(BuildContext context, CalendarData data) builder;

  const CalendarDataBuilder({super.key, required this.builder});

  @override
  State<CalendarDataBuilder> createState() => _CalendarDataBuilderState();
}

class _CalendarDataBuilderState extends State<CalendarDataBuilder> {
  final _recordRepo = locator.get<CalorieRecordRepositoryInterface>();
  final _gapRepo = locator.get<TrackingGapRepositoryInterface>();

  CalendarData? _data;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final profile = await ProfileResolver().resolve();
    final nutrition = await _recordRepo.fetchDayNutrition(profile);
    final gaps = await _gapRepo.fetchByProfile(profile);

    if (mounted) {
      setState(() {
        _data = CalendarData(
          profileId: profile.id!,
          goal: profile.caloriesLimitGoal,
          nutrition: nutrition,
          gaps: gaps,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;

    return BlocListener<HomeBloc, AbstractHomeState>(
      listener: (context, state) {
        if (state is HomeFetched) {
          _load();
        }
      },
      child: data == null
          ? const SizedBox.shrink()
          : widget.builder(context, data),
    );
  }
}
