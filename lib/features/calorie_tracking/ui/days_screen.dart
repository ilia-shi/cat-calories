import 'package:cat_calories/app/state/home_bloc.dart';
import 'package:cat_calories/app/state/home_event.dart';
import 'package:cat_calories/app/state/home_state.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/day_status.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/tracking_gap.dart';
import 'package:cat_calories/features/calorie_tracking/ui/day_calories_page.dart';
import 'package:cat_calories/features/calorie_tracking/ui/tracking_gaps_screen.dart';
import 'package:cat_calories/features/calorie_tracking/ui/tracking_gap_form_screen.dart';
import 'package:cat_calories/common/theme/colors.dart';
import 'package:cat_calories/common/widgets/app_top_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

final class DaysScreen extends StatelessWidget {
  DaysScreen({Key? key}) : super(key: key);

  void _openGaps(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const TrackingGapsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(
        title: 'Days',
        actions: [
          AppTopBarAction(
            icon: Icons.event_busy_outlined,
            tooltip: 'Not tracked periods',
            onPressed: () => _openGaps(context),
          ),
        ],
      ),
      body: BlocBuilder<HomeBloc, AbstractHomeState>(
        builder: (context, state) {
          if (state is HomeFetchingInProgress) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state is HomeFetched) {
            final today = state.todayDayStat();
            final stats = [
              if (today != null) today,
              ...state.recentDayStats(),
            ];

            return ListView.builder(
              itemCount: stats.length,
              itemBuilder: (BuildContext context, int index) {
                return _DayTile(
                  key: ValueKey(stats[index].day),
                  stat: stats[index],
                  state: state,
                  onOpenGaps: () => _openGaps(context),
                );
              },
            );
          }

          return Center(
            child: Text('Error'),
          );
        },
      ),
    );
  }
}

class _DayTile extends StatelessWidget {
  final DayStat stat;
  final HomeFetched state;
  final VoidCallback onOpenGaps;

  const _DayTile({
    super.key,
    required this.stat,
    required this.state,
    required this.onOpenGaps,
  });

  void _markNotTracked(BuildContext context) {
    final (start, end) = wholeDayBounds(stat.day, DateTime.now());

    TrackingGapFormScreen.open(
      context,
      profileId: state.activeProfile.id!,
      start: start,
      end: end,
    );
  }

  void _onTap(BuildContext context) {
    switch (stat.status) {
      case DayStatus.empty:
        _markNotTracked(context);
      case DayStatus.unknown:
        onOpenGaps();
      case DayStatus.tracked || DayStatus.partial:
        _showOptions(context);
    }
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet<dynamic>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) {
        return Wrap(
          children: <Widget>[
            ListTile(
              title: Text('Show calorie items'),
              onTap: () {
                Navigator.of(sheetContext).pop();

                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => DayCaloriesPage(stat.day)),
                );
              },
            ),
            ListTile(
              title: Text('Mark as not tracked'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _markNotTracked(context);
              },
            ),
            ListTile(
              title: Text('Remove day calories'),
              onTap: () {
                showDialog(
                  context: sheetContext,
                  builder: (BuildContext dialogContext) {
                    return AlertDialog(
                      title: Text('Remove day calories'),
                      content: Text('Continue?'),
                      actions: [
                        MaterialButton(
                          child: Text("Cancel"),
                          onPressed: () {
                            Navigator.pop(dialogContext);
                          },
                        ),
                        MaterialButton(
                          child: Text('Ok'),
                          onPressed: () {
                            BlocProvider.of<HomeBloc>(dialogContext).add(
                                RemovingCaloriesByCreatedAtDayEvent(
                                    stat.result!.day, state.activeProfile));

                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                                SnackBar(content: Text('Day removed')));

                            Navigator.of(dialogContext).pop();
                            Navigator.of(dialogContext).pop();
                          },
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final result = stat.result;

    return ListTile(
      leading: Icon(stat.status == DayStatus.empty
          ? Icons.event_busy_outlined
          : Icons.calendar_today_outlined),
      contentPadding: EdgeInsets.fromLTRB(25, 10, 25, 10),
      tileColor: stat.status == DayStatus.empty
          ? Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1)
          : null,
      title: Text(stat.status == DayStatus.unknown
          ? stat.displayKcal
          : '${stat.displayKcal} kcal'),
      trailing: result == null
          ? null
          : Padding(
              padding: EdgeInsets.fromLTRB(0, 10, 0, 0),
              child: Column(
                children: [
                  Text(
                    result.negativeValueSum == 0
                        ? '-0.00'
                        : result.negativeValueSum.toStringAsFixed(2),
                    style: TextStyle(fontSize: 12, color: SuccessColor),
                  ),
                  Text(
                    '+' + result.positiveValueSum.toStringAsFixed(2),
                    style: TextStyle(fontSize: 12, color: DangerColor),
                  ),
                ],
              )),
      subtitle: Text(DateFormat('MMM d, y').format(stat.day)),
      onTap: () => _onTap(context),
    );
  }
}
