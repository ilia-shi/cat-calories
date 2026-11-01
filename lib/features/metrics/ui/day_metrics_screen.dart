import 'package:cat_calories/app/state/home_bloc.dart';
import 'package:cat_calories/app/state/home_state.dart';
import 'package:cat_calories/common/locator.dart';
import 'package:cat_calories/common/theme/colors.dart';
import 'package:cat_calories/common/widgets/app_top_bar.dart';
import 'package:cat_calories/features/metrics/ui/day_metric_input_sheet.dart';
import 'package:cat_calories/features/metrics/ui/day_metrics_cubit.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/record_day.dart';
import 'package:cat_calories_core/features/metrics/domain/day_metric.dart';
import 'package:cat_calories_core/features/metrics/domain/day_metric_repository_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

const double _rowHeight = 56;

class DayMetricsScreen extends StatelessWidget {
  const DayMetricsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, AbstractHomeState>(
      buildWhen: (previous, current) => current is HomeFetched,
      builder: (context, state) {
        if (state is! HomeFetched) {
          return const Scaffold(
            appBar: AppTopBar(title: 'Metrics'),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return BlocProvider(
          key: ValueKey(state.activeProfile.id),
          create: (_) => DayMetricsCubit(
            locator.get<DayMetricRepositoryInterface>(),
            state.activeProfile,
          )..load(),
          child: const DayMetricsView(),
        );
      },
    );
  }
}

class DayMetricsView extends StatefulWidget {
  const DayMetricsView({super.key});

  @override
  State<DayMetricsView> createState() => _DayMetricsViewState();
}

class _DayMetricsViewState extends State<DayMetricsView> {
  final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _pickDay() async {
    final cubit = context.read<DayMetricsCubit>();
    final today = dayOf(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: today,
      firstDate: DateTime(2000),
      lastDate: today,
    );
    if (picked == null || !mounted) {
      return;
    }

    await cubit.showFrom(picked);
    final index = cubit.state.days.indexOf(dayOf(picked));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo((index * _rowHeight)
            .clamp(0.0, _scroll.position.maxScrollExtent));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(
        title: 'Metrics',
        actions: [
          AppTopBarAction(
            icon: Icons.calendar_month_outlined,
            tooltip: 'Go to a date',
            onPressed: _pickDay,
          ),
        ],
      ),
      body: BlocBuilder<DayMetricsCubit, DayMetricsState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              const _HeaderRow(),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: context.read<DayMetricsCubit>().load,
                  child: ListView.builder(
                    controller: _scroll,
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemExtent: _rowHeight,
                    itemCount: state.days.length,
                    itemBuilder: (context, index) =>
                        _DayRow(day: state.days[index], state: state),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow();

  @override
  Widget build(BuildContext context) {
    final color = AppColors.of(context).textSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const SizedBox(width: _DayRow.dateWidth),
          for (final metric in DayMetric.values)
            Expanded(
              child: Text(
                metric.title,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: color),
              ),
            ),
        ],
      ),
    );
  }
}

class _DayRow extends StatelessWidget {
  static const double dateWidth = 64;

  final DateTime day;
  final DayMetricsState state;

  const _DayRow({required this.day, required this.state});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          SizedBox(
            width: dateWidth,
            child: Text(
              DateFormat('E d MMM').format(day),
              style: TextStyle(
                fontSize: 12,
                color: AppColors.of(context).textSecondary,
              ),
            ),
          ),
          for (final metric in DayMetric.values)
            Expanded(
              child: _MetricCell(day: day, metric: metric, state: state),
            ),
        ],
      ),
    );
  }
}

class _MetricCell extends StatelessWidget {
  final DateTime day;
  final DayMetric metric;
  final DayMetricsState state;

  const _MetricCell({
    required this.day,
    required this.metric,
    required this.state,
  });

  void _openSheet(BuildContext context) {
    final cubit = context.read<DayMetricsCubit>();
    final entry = state.entryFor(day, metric);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => DayMetricInputSheet(
        metric: metric,
        day: day,
        entry: entry,
        onSave: (value, note) {
          Navigator.of(sheetContext).pop();
          cubit.save(metric, day, value, note);
        },
        onClear: () {
          Navigator.of(sheetContext).pop();
          cubit.clear(entry!);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final entry = state.entryFor(day, metric);

    return InkWell(
      onTap: () => _openSheet(context),
      child: Center(
        child: Text(
          entry == null ? '—' : metric.format(entry.value),
          textAlign: TextAlign.center,
          maxLines: 2,
          style: TextStyle(
            fontSize: 13,
            color: entry == null ? AppColors.of(context).textDisabled : null,
          ),
        ),
      ),
    );
  }
}
