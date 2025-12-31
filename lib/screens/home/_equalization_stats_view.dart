// lib/screens/home/_equalization_stats_view.dart

import 'package:cat_calories/blocs/home/home_bloc.dart';
import 'package:cat_calories/blocs/home/home_state.dart';
import 'package:cat_calories/models/calorie_recommendation_model.dart';
import 'package:cat_calories/ui/colors.dart';
import 'package:cat_calories/ui/widgets/progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class EqualizationStatsView extends StatelessWidget {
  const EqualizationStatsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, AbstractHomeState>(
      builder: (context, state) {
        if (state is HomeFetchingInProgress) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is HomeFetched && state.recommendation != null) {
          final rec = state.recommendation!;
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              _buildTodayCard(context, rec),
              const SizedBox(height: 12),
              _buildPacingCard(context, rec),
              const SizedBox(height: 12),
              _buildForecastCard(context, rec),
              const SizedBox(height: 12),
              _buildCompensationCard(context, rec),
            ],
          );
        }

        return const Center(child: Text('No data available'));
      },
    );
  }

  Widget _buildTodayCard(BuildContext context, CalorieRecommendationModel rec) {
    final progressPercent = (rec.consumedToday / rec.recommendedToday * 100)
        .clamp(0.0, 100.0);
    final isOver = rec.consumedToday > rec.recommendedToday;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Today\'s Goal',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                _buildAdjustmentBadge(rec.adjustment),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                SizedBox(
                  height: 80,
                  width: 80,
                  child: CustomPaint(
                    child: Center(
                      child: Text(
                        '${progressPercent.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    foregroundPainter: ProgressPainter(
                      defaultCircleColor: Colors.grey.shade200,
                      percentageCompletedCircleColor:
                      isOver ? DangerColor : SuccessColor,
                      completedPercentage: progressPercent,
                      circleWidth: 6.0,
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${rec.consumedToday.toStringAsFixed(0)} / ${rec.recommendedToday.toStringAsFixed(0)} kcal',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Base goal: ${rec.baseGoal.toStringAsFixed(0)} kcal',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        rec.remainingToday >= 0
                            ? 'Remaining: ${rec.remainingToday.toStringAsFixed(0)} kcal'
                            : 'Over by: ${rec.remainingToday.abs().toStringAsFixed(0)} kcal',
                        style: TextStyle(
                          color: rec.remainingToday >= 0
                              ? SuccessColor
                              : DangerColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdjustmentBadge(double adjustment) {
    if (adjustment.abs() < 1) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text('On track', style: TextStyle(fontSize: 12)),
      );
    }

    final isReduction = adjustment < 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isReduction
            ? SuccessColor.withOpacity(0.1)
            : DangerColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '${isReduction ? '' : '+'}${adjustment.toStringAsFixed(0)} kcal',
        style: TextStyle(
          fontSize: 12,
          color: isReduction ? SuccessColor : DangerColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildPacingCard(BuildContext context, CalorieRecommendationModel rec) {
    final pacing = rec.pacing;
    if (pacing == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Eating Pace',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: Colors.blue.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      pacing.message,
                      style: TextStyle(color: Colors.blue.shade900),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildPacingStat(
                  Icons.access_time,
                  '${pacing.remainingHours.toStringAsFixed(1)}h',
                  'Time left',
                ),
                _buildPacingStat(
                  Icons.restaurant,
                  '${pacing.suggestedRemainingMeals}',
                  'Meals left',
                ),
                _buildPacingStat(
                  Icons.local_fire_department,
                  '${pacing.caloriesPerRemainingHour.toStringAsFixed(0)}',
                  'kcal/hour',
                ),
              ],
            ),
            if (pacing.nextEatTime != null) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.timer, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Next meal at ${DateFormat('HH:mm').format(pacing.nextEatTime!)}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPacingStat(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey.shade600),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildForecastCard(
      BuildContext context, CalorieRecommendationModel rec) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Upcoming Days',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            ...rec.forecast.take(5).map((day) {
              final isReduction = day.adjustment < 0;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 80,
                      child: Text(
                        DateFormat('EEE, MMM d').format(day.date),
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: day.recommendedCalories / rec.baseGoal,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation(
                          isReduction ? SuccessColor : DangerColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 70,
                      child: Text(
                        '${day.recommendedCalories.toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildCompensationCard(
      BuildContext context, CalorieRecommendationModel rec) {
    if (rec.compensationBreakdown.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Compensation Breakdown',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                Text(
                  'Total: ${rec.accumulatedDeviation >= 0 ? '+' : ''}${rec.accumulatedDeviation.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: rec.accumulatedDeviation > 0
                        ? DangerColor
                        : SuccessColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'How past days affect today\'s goal',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            const SizedBox(height: 12),
            ...rec.compensationBreakdown.map((day) {
              final isSurplus = day.deviation > 0;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    SizedBox(
                      width: 70,
                      child: Text(
                        DateFormat('MMM d').format(day.date),
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '${day.consumed.toStringAsFixed(0)} kcal',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    SizedBox(
                      width: 60,
                      child: Text(
                        '${isSurplus ? '+' : ''}${day.deviation.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: isSurplus ? DangerColor : SuccessColor,
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 40,
                      child: Text(
                        '×${day.weight.toStringAsFixed(1)}',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 11,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}