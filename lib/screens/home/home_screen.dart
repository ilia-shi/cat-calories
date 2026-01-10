import 'dart:async';

import 'package:cat_calories/blocs/home/home_bloc.dart';
import 'package:cat_calories/blocs/home/home_event.dart';
import 'package:cat_calories/blocs/home/home_state.dart';
import 'package:cat_calories/screens/calories/day_calories_page.dart';
import 'package:cat_calories/screens/calories_history.dart';
import 'package:cat_calories/screens/create_product_screen.dart';
import 'package:cat_calories/screens/home/tabs/tracking_tab.dart';
import 'package:cat_calories/screens/home/widgets/app_drawer.dart';
import 'package:cat_calories/screens/home/widgets/calorie_chip.dart';
import 'package:cat_calories/screens/home/widgets/floating_action_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../service/calorie_exporter.dart';
import '../days_screen.dart';
import '../waking_periods_screen.dart';
import 'tabs/main_info_tab.dart';

class HomeScreen extends StatefulWidget {
  HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  TextEditingController _calorieItemController = TextEditingController();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _calorieItemController = TextEditingController();

    _timer = Timer.periodic(Duration(seconds: 5), (Timer t) {
      setState(() {});
    });

    _calorieItemController.addListener(() {
      BlocProvider.of<HomeBloc>(context)
          .add(CaloriePreparedEvent(_calorieItemController.text));
    });
  }

  @override
  void dispose() {
    _calorieItemController.dispose();

    if (_timer != null) {
      _timer!.cancel();
    }

    super.dispose();
  }

  _HomeScreenState();

  /// Show export options dialog
  void _showExportDialog(BuildContext context, HomeFetched state) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Export to JSON'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Choose what to export:'),
              const SizedBox(height: 16),
              _ExportSummaryWidget(state: state),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _exportToday(context, state);
              },
              child: const Text('Today'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _exportPeriod(context, state);
              },
              child: const Text('Period'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _exportAll(context, state);
              },
              child: const Text('All Data'),
            ),
          ],
        );
      },
    );
  }

  /// Export today's calorie items
  Future<void> _exportToday(BuildContext context, HomeFetched state) async {
    try {
      _showLoadingSnackBar(context, 'Preparing export...');

      await CalorieExporter.exportTodayAndShare(
        todayCalorieItems: state.todayCalorieItems,
        profile: state.activeProfile,
      );

      _showSuccessSnackBar(context, 'Today\'s data exported successfully!');
    } catch (e) {
      _showErrorSnackBar(context, 'Export failed: $e');
    }
  }

  /// Export current period's calorie items
  Future<void> _exportPeriod(BuildContext context, HomeFetched state) async {
    try {
      _showLoadingSnackBar(context, 'Preparing export...');

      await CalorieExporter.exportPeriodAndShare(
        periodCalorieItems: state.periodCalorieItems,
        profile: state.activeProfile,
        currentWakingPeriod: state.currentWakingPeriod,
      );

      _showSuccessSnackBar(context, 'Period data exported successfully!');
    } catch (e) {
      _showErrorSnackBar(context, 'Export failed: $e');
    }
  }

  /// Export all data including products and waking periods
  Future<void> _exportAll(BuildContext context, HomeFetched state) async {
    try {
      _showLoadingSnackBar(context, 'Preparing export...');

      // Combine all calorie items (today + period + rolling window)
      final allItems = <int, dynamic>{};
      for (final item in state.todayCalorieItems) {
        if (item.id != null) allItems[item.id!] = item;
      }
      for (final item in state.periodCalorieItems) {
        if (item.id != null) allItems[item.id!] = item;
      }
      for (final item in state.rollingWindowCalorieItems) {
        if (item.id != null) allItems[item.id!] = item;
      }

      await CalorieExporter.exportAndShare(
        calorieItems: allItems.values.toList().cast(),
        profile: state.activeProfile,
        products: state.products,
        wakingPeriods: state.wakingPeriods,
        exportType: 'full',
      );

      _showSuccessSnackBar(context, 'All data exported successfully!');
    } catch (e) {
      _showErrorSnackBar(context, 'Export failed: $e');
    }
  }

  void _showLoadingSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 16),
            Text(message),
          ],
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 16),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 16),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    BlocProvider.of<HomeBloc>(context)
        .add(CalorieItemListFetchingInProgressEvent());

    final List<PopupMenuEntry<String>> menuItems = [
      const PopupMenuItem<String>(
        value: 'export_json',
        child: ListTile(
          leading: Icon(Icons.file_download),
          title: Text('Export to JSON'),
        ),
      ),
      const PopupMenuDivider(),
      const PopupMenuItem<String>(
        value: 'calories',
        child: ListTile(title: Text('Calories')),
      ),
      const PopupMenuItem<String>(
        value: 'create_product',
        child: ListTile(title: Text('Create product')),
      ),
      const PopupMenuItem<String>(
        value: 'days',
        child: ListTile(title: Text('Days (legacy)')),
      ),
      const PopupMenuItem<String>(
        value: 'periods',
        child: ListTile(title: Text('Waking Periods (legacy)')),
      ),
    ];

    void _handleMenuSelection(
        BuildContext context, String value, HomeFetched state) {
      // Handle export separately
      if (value == 'export_json') {
        _showExportDialog(context, state);
        return;
      }

      final routes = <String, Widget Function()>{
        'create_product': () => CreateProductScreen(state.activeProfile),
        'calories': () => DayCaloriesPage(state.startDate),
        'days': () => DaysScreen(),
        'periods': () => WakingPeriodsScreen(),
      };

      final builder = routes[value];
      if (builder != null) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => builder()));
      }
    }

    const tabMenuItems = [
      Tab(text: 'Tracking'),
      Tab(text: 'kCal'),
      Tab(text: 'Info'),
    ];

    var tabViews = [
      TrackingTab(),
      AllCaloriesHistoryScreen(),
      MainInfoView(),
    ];

    return Scaffold(
      body: Scaffold(
        body: DefaultTabController(
          length: tabViews.length,
          child: Scaffold(
            drawer: Drawer(
              child: HomeAppDrawer(),
            ),
            appBar: AppBar(
              actions: [
                BlocBuilder<HomeBloc, AbstractHomeState>(
                    builder: (context, state) {
                      if (state is HomeFetched) {
                        return PopupMenuButton(
                          itemBuilder: (BuildContext context) {
                            return menuItems;
                          },
                          onSelected: (String value) =>
                              _handleMenuSelection(context, value, state),
                        );
                      }

                      return PopupMenuButton(
                        enabled: false,
                        itemBuilder: (BuildContext context) {
                          return [];
                        },
                      );
                    }),
              ],
              bottom: TabBar(
                labelStyle: TextStyle(
                  fontSize: 12,
                ),
                tabs: tabMenuItems,
              ),
              title: BlocBuilder<HomeBloc, AbstractHomeState>(
                builder: (context, state) {
                  if (state is HomeFetched) {
                    return _CompactCalorieDisplay(state: state);
                  }

                  return Text('...');
                },
              ),
            ),
            body: TabBarView(
              children: tabViews,
            ),
          ),
        ),
      ),
      floatingActionButton: const HomeFloatingActionButton(),
    );
  }
}

/// Widget showing export summary in the dialog
class _ExportSummaryWidget extends StatelessWidget {
  final HomeFetched state;

  const _ExportSummaryWidget({required this.state});

  @override
  Widget build(BuildContext context) {
    final todaySummary = CalorieExporter.getExportSummary(state.todayCalorieItems);
    final periodSummary = CalorieExporter.getExportSummary(state.periodCalorieItems);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SummaryRow(
            label: 'Today',
            value: '${todaySummary['eaten_items']} items, ${todaySummary['total_calories'].toStringAsFixed(0)} kcal',
          ),
          const SizedBox(height: 4),
          _SummaryRow(
            label: 'Period',
            value: '${periodSummary['eaten_items']} items, ${periodSummary['total_calories'].toStringAsFixed(0)} kcal',
          ),
          const SizedBox(height: 4),
          _SummaryRow(
            label: 'Products',
            value: '${state.products.length} items',
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        Text(value, style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
      ],
    );
  }
}

class _CompactCalorieDisplay extends StatelessWidget {
  final HomeFetched state;

  const _CompactCalorieDisplay({required this.state});

  @override
  Widget build(BuildContext context) {
    // Period calories
    final periodEaten = state.getPeriodCaloriesEatenSum();
    final periodGoal = state.currentWakingPeriod?.caloriesLimitGoal ??
        state.activeProfile.caloriesLimitGoal;
    final periodOver = periodEaten > periodGoal;

    final todayEaten = state.getTodayCaloriesEatenSum();
    final todayGoal = state.activeProfile.caloriesLimitGoal;
    final todayOver = todayEaten > todayGoal;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CalorieChip(
          label: 'P',
          value: periodEaten.round(),
          goal: periodGoal.round(),
          isOver: periodOver,
          tooltip: 'Current Period',
        ),
        const SizedBox(width: 8),
        CalorieChip(
          label: 'T',
          value: todayEaten.round(),
          goal: todayGoal.round(),
          isOver: todayOver,
          tooltip: 'Today',
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}
