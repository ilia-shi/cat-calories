import 'package:cat_calories/app/profile_resolver.dart';
import 'package:cat_calories/app/state/home_bloc.dart';
import 'package:cat_calories/app/state/home_state.dart';
import 'package:cat_calories/common/locator.dart';
import 'package:cat_calories/common/theme/colors.dart';
import 'package:cat_calories/common/widgets/app_card.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/calorie_record_repository_interface.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/weekly_totals.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

/// Calories eaten per week over the last [weeks] weeks, this week included.
final class StatsWidget extends StatefulWidget {
  final int weeks;

  const StatsWidget({super.key, this.weeks = 12});

  @override
  State<StatsWidget> createState() => _StatsWidgetState();
}

final class _StatsWidgetState extends State<StatsWidget> {
  final _recordRepo = locator.get<CalorieRecordRepositoryInterface>();

  List<WeekTotal>? _totals;

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

    if (mounted) {
      setState(() {
        _totals = weeklyTotals(days, now: DateTime.now(), weeks: widget.weeks);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final totals = _totals;

    return BlocListener<HomeBloc, AbstractHomeState>(
      listener: (context, state) {
        if (state is HomeFetched) {
          _load();
        }
      },
      child: totals == null
          ? const SizedBox.shrink()
          : WeeklyCaloriesCard(totals: totals),
    );
  }
}

final class WeeklyCaloriesCard extends StatelessWidget {
  final List<WeekTotal> totals;

  const WeeklyCaloriesCard({super.key, required this.totals});

  String _rangeLabel() {
    final start = totals.first.weekStart;
    final lastStart = totals.last.weekStart;
    final end = DateTime(lastStart.year, lastStart.month, lastStart.day + 6);
    final format =
        DateFormat(start.year == end.year ? 'd MMM' : 'd MMM y');

    return '${format.format(start)} – ${format.format(end)}';
  }

  @override
  Widget build(BuildContext context) {
    final appColors = AppColors.of(context);
    final maxKcal = totals.fold<double>(0, (m, w) => w.kcal > m ? w.kcal : m);

    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Calories per week',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: appColors.textPrimary,
                  ),
                ),
              ),
              if (totals.isNotEmpty)
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
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < totals.length; i++) ...[
                  if (i > 0) const SizedBox(width: 6),
                  Expanded(
                    child: _WeekBar(
                      total: totals[i],
                      fraction: maxKcal > 0 ? totals[i].kcal / maxKcal : 0,
                      isCurrent: i == totals.length - 1,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

final class _WeekBar extends StatelessWidget {
  static final _dateFormat = DateFormat('d MMM');

  final WeekTotal total;
  final double fraction;
  final bool isCurrent;

  const _WeekBar({
    required this.total,
    required this.fraction,
    required this.isCurrent,
  });

  static String _compact(double kcal) {
    if (kcal >= 1000) {
      return '${(kcal / 1000).toStringAsFixed(1)}k';
    }
    return kcal.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final appColors = AppColors.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final labelStyle = TextStyle(fontSize: 10, color: appColors.textSecondary);

    return Column(
      children: [
        Text(
          _compact(total.kcal),
          maxLines: 1,
          style: labelStyle.copyWith(
            fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              heightFactor: fraction,
              widthFactor: 1,
              child: DecoratedBox(
                decoration: ShapeDecoration(
                  shape: AppCard.squircleBorder(radius: 6),
                  color: isCurrent ? primary : primary.withValues(alpha: 0.35),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _dateFormat.format(total.weekStart),
          maxLines: 1,
          overflow: TextOverflow.clip,
          style: labelStyle,
        ),
      ],
    );
  }
}
