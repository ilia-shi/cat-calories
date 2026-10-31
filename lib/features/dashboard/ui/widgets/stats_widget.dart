import 'package:cat_calories/app/profile_resolver.dart';
import 'package:cat_calories/app/state/home_bloc.dart';
import 'package:cat_calories/app/state/home_state.dart';
import 'package:cat_calories/common/locator.dart';
import 'package:cat_calories/common/theme/colors.dart';
import 'package:cat_calories/common/widgets/app_card.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/calorie_record_repository_interface.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/tracking_gap_repository_interface.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/weekly_averages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

/// Average kcal per day of the last [weeks] weeks, this week included.
final class StatsWidget extends StatefulWidget {
  final int weeks;

  const StatsWidget({super.key, this.weeks = 12});

  @override
  State<StatsWidget> createState() => _StatsWidgetState();
}

final class _StatsWidgetState extends State<StatsWidget> {
  final _recordRepo = locator.get<CalorieRecordRepositoryInterface>();
  final _gapRepo = locator.get<TrackingGapRepositoryInterface>();

  List<WeekAverage>? _averages;
  double _goal = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final profile = await ProfileResolver().resolve();
    // One row per day that has eaten records, so this many rows always reach
    // back past the oldest week shown.
    final days =
        await _recordRepo.fetchDaysByProfile(profile, widget.weeks * 7);
    final gaps = await _gapRepo.fetchByProfile(profile);
    final firstRecordDay = await _recordRepo.fetchFirstRecordDay(profile);

    if (mounted) {
      setState(() {
        _goal = profile.caloriesLimitGoal;
        _averages = weeklyAverages(
          days,
          gaps: gaps,
          firstRecordDay: firstRecordDay,
          now: DateTime.now(),
          weeks: widget.weeks,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final averages = _averages;

    return BlocListener<HomeBloc, AbstractHomeState>(
      listener: (context, state) {
        if (state is HomeFetched) {
          _load();
        }
      },
      child: averages == null
          ? const SizedBox.shrink()
          : WeeklyCaloriesCard(averages: averages, goal: _goal),
    );
  }
}

final class WeeklyCaloriesCard extends StatelessWidget {
  static const double _chartHeight = 100;
  static const double _barGap = 6;

  /// A bar is about 20 logical pixels wide on a 360-wide phone, too narrow for
  /// a label, so only every [_labelEvery]-th bar gets one, counted from the
  /// current week.
  static const int _labelEvery = 3;

  final List<WeekAverage> averages;
  final double goal;

  const WeeklyCaloriesCard({
    super.key,
    required this.averages,
    required this.goal,
  });

  String _rangeLabel() {
    final start = averages.first.weekStart;
    final lastStart = averages.last.weekStart;
    final end = DateTime(lastStart.year, lastStart.month, lastStart.day + 6);
    final format =
        DateFormat(start.year == end.year ? 'd MMM' : 'd MMM y');

    return '${format.format(start)} – ${format.format(end)}';
  }

  List<Widget> _labels() {
    final labels = <Widget>[];
    for (var end = averages.length; end > 0; end -= _labelEvery) {
      final start = end > _labelEvery ? end - _labelEvery : 0;
      labels.insert(
        0,
        Expanded(
          flex: end - start,
          child: _WeekLabel(average: averages[end - 1]),
        ),
      );
    }

    return labels;
  }

  @override
  Widget build(BuildContext context) {
    final appColors = AppColors.of(context);
    final scale = averages.fold<double>(
      goal,
      (max, week) => (week.kcalPerDay ?? 0) > max ? week.kcalPerDay! : max,
    );

    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Average kcal per day',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: appColors.textPrimary,
                  ),
                ),
              ),
              if (averages.isNotEmpty)
                Text(
                  _rangeLabel(),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: appColors.textSecondary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: _chartHeight,
            child: Stack(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (var i = 0; i < averages.length; i++) ...[
                      if (i > 0) const SizedBox(width: _barGap),
                      Expanded(
                        child: _WeekBar(
                          kcalPerDay: averages[i].kcalPerDay,
                          scale: scale,
                          isCurrent: i == averages.length - 1,
                        ),
                      ),
                    ],
                  ],
                ),
                if (scale > 0)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: _chartHeight * goal / scale,
                    child: Container(height: 1, color: appColors.textSecondary),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Row(children: _labels()),
        ],
      ),
    );
  }
}

final class _WeekBar extends StatelessWidget {
  static const double _noDataHeight = 4;

  final double? kcalPerDay;
  final double scale;
  final bool isCurrent;

  const _WeekBar({
    required this.kcalPerDay,
    required this.scale,
    required this.isCurrent,
  });

  @override
  Widget build(BuildContext context) {
    final kcal = kcalPerDay;

    if (kcal == null) {
      return Align(
        alignment: Alignment.bottomCenter,
        child: SizedBox(
          height: _noDataHeight,
          width: double.infinity,
          child: DecoratedBox(
            decoration: ShapeDecoration(
              shape: AppCard.squircleBorder(radius: 2),
              color: AppColors.of(context).surfaceMuted,
            ),
          ),
        ),
      );
    }

    final primary = Theme.of(context).colorScheme.primary;

    return Align(
      alignment: Alignment.bottomCenter,
      child: FractionallySizedBox(
        heightFactor: scale > 0 ? kcal / scale : 0,
        widthFactor: 1,
        child: DecoratedBox(
          decoration: ShapeDecoration(
            shape: AppCard.squircleBorder(radius: 6),
            color: isCurrent ? primary : primary.withValues(alpha: 0.35),
          ),
        ),
      ),
    );
  }
}

final class _WeekLabel extends StatelessWidget {
  static final _dateFormat = DateFormat('d MMM');

  final WeekAverage average;

  const _WeekLabel({required this.average});

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: 10,
      color: AppColors.of(context).textSecondary,
    );
    final kcal = average.kcalPerDay;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(kcal == null ? '—' : '${kcal.round()}', maxLines: 1, style: style),
        Text(_dateFormat.format(average.weekStart), maxLines: 1, style: style),
      ],
    );
  }
}
