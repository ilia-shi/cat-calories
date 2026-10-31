import 'package:cat_calories/app/state/home_bloc.dart';
import 'package:cat_calories/app/state/home_event.dart';
import 'package:cat_calories/app/state/home_state.dart';
import 'package:cat_calories/common/widgets/app_top_bar.dart';
import 'package:cat_calories/features/calorie_tracking/ui/widgets/tracking_gap_sheet.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/record_day.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/tracking_gap.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class TrackingGapsScreen extends StatelessWidget {
  const TrackingGapsScreen({super.key});

  void _add(BuildContext context, HomeFetched state) {
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final (start, end) = wholeDayBounds(dayOf(yesterday), now);

    TrackingGapSheet.show(
      context,
      profileId: state.activeProfile.id!,
      start: start,
      end: end,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, AbstractHomeState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppTopBar(
            title: 'Not tracked',
            actions: [
              if (state is HomeFetched)
                AppTopBarAction(
                  icon: Icons.add,
                  tooltip: 'Add a gap',
                  onPressed: () => _add(context, state),
                ),
            ],
          ),
          body: switch (state) {
            HomeFetched() when state.trackingGaps.isEmpty => const Center(
                child: Text('No gaps yet'),
              ),
            HomeFetched() => ListView.builder(
                itemCount: state.trackingGaps.length,
                itemBuilder: (context, index) => _GapTile(
                  gap: state.trackingGaps[index],
                  profileId: state.activeProfile.id!,
                ),
              ),
            HomeFetchingInProgress() => const Center(
                child: CircularProgressIndicator(),
              ),
            HomeError() => const Center(child: Text('Error')),
          },
        );
      },
    );
  }
}

class _GapTile extends StatelessWidget {
  static final _format = DateFormat('MMM d, HH:mm');

  final TrackingGap gap;
  final String profileId;

  const _GapTile({required this.gap, required this.profileId});

  void _confirmDelete(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove gap'),
        content: const Text('Continue?'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
          TextButton(
            child: const Text('Ok'),
            onPressed: () {
              context.read<HomeBloc>().add(TrackingGapDeletingEvent(gap));
              Navigator.of(dialogContext).pop();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final description = gap.description;

    return ListTile(
      contentPadding: const EdgeInsets.fromLTRB(25, 10, 15, 10),
      title: Text(
        '${_format.format(gap.startedAt)} - ${_format.format(gap.endedAt)}',
      ),
      subtitle: description == null
          ? null
          : Text(description, maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        tooltip: 'Remove gap',
        onPressed: () => _confirmDelete(context),
      ),
      onTap: () => TrackingGapSheet.show(
        context,
        gap: gap,
        profileId: profileId,
        start: gap.startedAt,
        end: gap.endedAt,
      ),
    );
  }
}
