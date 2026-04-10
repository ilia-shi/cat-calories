import 'dart:async';

import 'package:cat_calories/blocs/home/home_bloc.dart';
import 'package:cat_calories/blocs/home/home_event.dart';
import 'package:cat_calories/blocs/home/home_state.dart';
import 'package:cat_calories/screens/calories/day_calories_page.dart';
import 'package:cat_calories/screens/calories/calories_history.dart';
import 'package:cat_calories/screens/home/tabs/main_info_tab.dart';
import 'package:cat_calories/screens/products/create_product_screen.dart';
import 'package:cat_calories/screens/home/tabs/products_tab.dart';
import 'package:cat_calories/screens/home/tabs/tracking_tab.dart';
import 'package:cat_calories/screens/home/widgets/app_drawer.dart';
import 'package:cat_calories/screens/home/widgets/calorie_chip.dart';
import 'package:cat_calories/screens/home/widgets/floating_action_button.dart';
import 'package:cat_calories/screens/products/categories_screen.dart';
import 'package:cat_calories/screens/profile/edit_profile_screen.dart';
import 'package:cat_calories/service/sync_service.dart';
import 'package:cat_calories/service/web_server_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../service/calorie_exporter.dart';
import '../calories/days_screen.dart';
import '../waking_periods/waking_periods_screen.dart';


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

    // Dispatch initial data fetch after the widget is fully mounted
    WidgetsBinding.instance.addPostFrameCallback((_) {
      BlocProvider.of<HomeBloc>(context)
          .add(CalorieItemListFetchingInProgressEvent());
    });

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
      final allItems = <String, dynamic>{};
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
        value: 'categories',
        child: ListTile(
          leading: Icon(Icons.category),
          title: Text('Manage Categories'),
        ),
      ),
      const PopupMenuDivider(),
      const PopupMenuItem<String>(
        value: 'calories',
        child: ListTile(title: Text('Calories')),
      ),
      const PopupMenuItem<String>(
        value: 'create_product',
        child: ListTile(title: Text('Create product (legacy)')),
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
        'categories': () => const ProductCategoriesScreen(),
      };

      final builder = routes[value];
      if (builder != null) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => builder()));
      }
    }

    const tabMenuItems = [
      Tab(text: 'Tracking'),
      Tab(text: 'Products'),
      Tab(text: 'kCal'),
      Tab(text: 'Info'),
    ];

    var tabViews = [
      TrackingTab(),
      const ProductsTab(),
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
                _SyncIndicator(),
                _WebServerIndicator(),
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
          const SizedBox(height: 4),
          _SummaryRow(
            label: 'Categories',
            value: '${state.productCategories.length} items',
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

class _WebServerIndicator extends StatefulWidget {
  @override
  State<_WebServerIndicator> createState() => _WebServerIndicatorState();
}

class _WebServerIndicatorState extends State<_WebServerIndicator> {
  final _webServer = GetIt.instance.get<WebServerService>();
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_webServer.isRunning) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => _showMenu(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Icon(
          Icons.lan,
          size: 16,
          color: Colors.green.shade400,
        ),
      ),
    );
  }

  void _showMenu(BuildContext context) {
    final address = _webServer.address ?? 'unknown';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1e1e2e) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Icon(Icons.lan, color: Colors.green.shade400, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        'Web Server',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Running',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green.shade400,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
                const Divider(height: 1),

                // Address
                ListTile(
                  leading: const Icon(Icons.link, size: 20),
                  title: const Text('Address', style: TextStyle(fontSize: 13, color: Colors.grey)),
                  subtitle: SelectableText(
                    'http://$address',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),

                // Port
                ListTile(
                  leading: const Icon(Icons.numbers, size: 20),
                  title: const Text('Port', style: TextStyle(fontSize: 13, color: Colors.grey)),
                  subtitle: Text(
                    '${WebServerService.defaultPort}',
                    style: TextStyle(
                      fontSize: 15,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ),

                // Hint
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Colors.grey.shade500),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Open the address on any device in the same network',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),
                const Divider(height: 1),

                // Disconnect
                ListTile(
                  leading: Icon(Icons.stop_circle_outlined, color: Colors.red.shade400, size: 22),
                  title: Text('Stop server', style: TextStyle(color: Colors.red.shade400)),
                  onTap: () async {
                    await _webServer.stop();
                    if (mounted) setState(() {});
                    if (sheetContext.mounted) Navigator.of(sheetContext).pop();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SyncIndicator extends StatefulWidget {
  @override
  State<_SyncIndicator> createState() => _SyncIndicatorState();
}

class _SyncIndicatorState extends State<_SyncIndicator> {
  final _syncService = GetIt.instance.get<SyncService>();
  late final Timer _timer;
  bool _hasToken = false;
  bool _syncEnabled = false;
  String _serverUrl = '';
  String _email = '';
  String? _lastSyncedAt;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _loadState();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) _loadState();
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<void> _loadState() async {
    final tok = await _syncService.token;
    final enabled = await _syncService.isEnabled;
    final url = await _syncService.serverUrl;
    final em = await _syncService.email;
    final prefs = await SharedPreferences.getInstance();
    final lastSync = prefs.getString('sync_last_synced_at');
    if (mounted) {
      setState(() {
        _hasToken = tok.isNotEmpty;
        _syncEnabled = enabled;
        _serverUrl = url;
        _email = em;
        _lastSyncedAt = lastSync;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _hasToken ? () => _doQuickSync(context) : () => _showDisconnectedMenu(context),
      onLongPress: _hasToken ? () => _showConnectedMenu(context) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: _isSyncing
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.green.shade400,
                ),
              )
            : Icon(
                Icons.sync_rounded,
                size: 18,
                color: _hasToken && _syncEnabled
                    ? Colors.green.shade400
                    : Colors.grey.shade500,
              ),
      ),
    );
  }

  Future<void> _doQuickSync(BuildContext context) async {
    if (_isSyncing) return;
    setState(() => _isSyncing = true);
    final success = await _syncService.sync();
    await _loadState();
    if (mounted) {
      setState(() => _isSyncing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Sync completed' : 'Sync failed'),
          duration: const Duration(seconds: 2),
          backgroundColor: success ? Colors.green.shade600 : Colors.red.shade600,
        ),
      );
    }
  }

  String _formatLastSync() {
    if (_lastSyncedAt == null) return 'Never';
    try {
      final dt = DateTime.parse(_lastSyncedAt!).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${dt.day}.${dt.month.toString().padLeft(2, '0')} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return _lastSyncedAt ?? 'Unknown';
    }
  }

  void _showConnectedMenu(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1e1e2e) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Icon(Icons.sync_rounded, color: Colors.green.shade400, size: 20),
                          const SizedBox(width: 10),
                          Text(
                            'Remote Sync',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _syncEnabled
                                  ? Colors.green.withValues(alpha: 0.15)
                                  : Colors.orange.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _syncEnabled ? 'Active' : 'Paused',
                              style: TextStyle(
                                fontSize: 12,
                                color: _syncEnabled ? Colors.green.shade400 : Colors.orange.shade400,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),
                    const Divider(height: 1),

                    // Server
                    ListTile(
                      leading: const Icon(Icons.dns_outlined, size: 20),
                      title: const Text('Server', style: TextStyle(fontSize: 13, color: Colors.grey)),
                      subtitle: Text(
                        _serverUrl,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),

                    // Email
                    ListTile(
                      leading: const Icon(Icons.email_outlined, size: 20),
                      title: const Text('Email', style: TextStyle(fontSize: 13, color: Colors.grey)),
                      subtitle: Text(
                        _email.isNotEmpty ? _email : '—',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),

                    // Last sync
                    ListTile(
                      leading: const Icon(Icons.schedule, size: 20),
                      title: const Text('Last sync', style: TextStyle(fontSize: 13, color: Colors.grey)),
                      subtitle: Text(
                        _formatLastSync(),
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),

                    const Divider(height: 1),

                    // Enable/disable sync
                    SwitchListTile(
                      secondary: const Icon(Icons.autorenew, size: 20),
                      title: const Text('Auto sync', style: TextStyle(fontSize: 15)),
                      value: _syncEnabled,
                      activeColor: Colors.green.shade400,
                      onChanged: (value) async {
                        await _syncService.setEnabled(value);
                        setSheetState(() => _syncEnabled = value);
                        setState(() => _syncEnabled = value);
                      },
                    ),

                    const Divider(height: 1),

                    // Sync now
                    ListTile(
                      leading: Icon(Icons.sync_rounded,
                          color: _isSyncing ? Colors.grey : Theme.of(context).colorScheme.primary, size: 22),
                      title: Text(
                        _isSyncing ? 'Syncing...' : 'Sync now',
                        style: TextStyle(
                          color: _isSyncing ? Colors.grey : Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      onTap: _isSyncing
                          ? null
                          : () async {
                              setSheetState(() => _isSyncing = true);
                              await _syncService.sync();
                              await _loadState();
                              if (sheetContext.mounted) {
                                setSheetState(() => _isSyncing = false);
                              }
                            },
                    ),

                    // Reconnect
                    ListTile(
                      leading: Icon(Icons.refresh, color: Colors.orange.shade400, size: 22),
                      title: Text('Reconnect', style: TextStyle(color: Colors.orange.shade400)),
                      onTap: () async {
                        Navigator.of(sheetContext).pop();
                        final success = await _syncService.reconnect();
                        if (success) {
                          await _syncService.setEnabled(true);
                          await _syncService.sync();
                        }
                        await _loadState();
                      },
                    ),

                    // Disconnect
                    ListTile(
                      leading: Icon(Icons.link_off, color: Colors.red.shade400, size: 22),
                      title: Text('Disconnect', style: TextStyle(color: Colors.red.shade400)),
                      onTap: () async {
                        await _syncService.setEnabled(false);
                        await _syncService.setToken('');
                        await _loadState();
                        if (sheetContext.mounted) Navigator.of(sheetContext).pop();
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showDisconnectedMenu(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1e1e2e) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Icon(Icons.sync_rounded, color: Colors.grey.shade500, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        'Remote Sync',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Not connected',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
                const Divider(height: 1),

                // Last sync
                ListTile(
                  leading: const Icon(Icons.schedule, size: 20),
                  title: const Text('Last sync', style: TextStyle(fontSize: 13, color: Colors.grey)),
                  subtitle: Text(
                    _formatLastSync(),
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),

                const Divider(height: 1),

                // Connect
                BlocBuilder<HomeBloc, AbstractHomeState>(
                  builder: (context, state) {
                    return ListTile(
                      leading: Icon(Icons.login_rounded,
                          color: Theme.of(context).colorScheme.primary, size: 22),
                      title: Text(
                        'Connect to server',
                        style: TextStyle(color: Theme.of(context).colorScheme.primary),
                      ),
                      onTap: () {
                        Navigator.of(sheetContext).pop();
                        if (state is HomeFetched) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditProfileScreen(state.activeProfile),
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}