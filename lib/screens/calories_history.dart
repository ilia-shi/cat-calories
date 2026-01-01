import 'package:cat_calories/blocs/home/home_bloc.dart';
import 'package:cat_calories/blocs/home/home_event.dart';
import 'package:cat_calories/blocs/home/home_state.dart';
import 'package:cat_calories/models/calorie_item_model.dart';
import 'package:cat_calories/models/profile_model.dart';
import 'package:cat_calories/repositories/calorie_item_repository.dart';
import 'package:cat_calories/screens/edit_calorie_item_screen.dart';
import 'package:cat_calories/service/profile_resolver.dart';
import 'package:cat_calories/ui/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';

class AllCaloriesHistoryScreen extends StatefulWidget {
  const AllCaloriesHistoryScreen({Key? key}) : super(key: key);

  @override
  State<AllCaloriesHistoryScreen> createState() =>
      _AllCaloriesHistoryScreenState();
}

class _AllCaloriesHistoryScreenState extends State<AllCaloriesHistoryScreen>
    with AutomaticKeepAliveClientMixin {
  final locator = GetIt.instance;
  late CalorieItemRepository calorieItemRepository =
  locator.get<CalorieItemRepository>();

  bool _isLoading = true;
  bool _isInitialLoad = true;
  Map<DateTime, List<CalorieItemModel>> _groupedCalories = {};
  Map<DateTime, _DaySummary> _daySummaries = {};
  List<DateTime> _sortedDates = [];
  Set<DateTime> _expandedDates = {};
  double _totalAllTime = 0;
  int _totalItems = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadAllCalories(showLoading: true);
  }

  Future<void> _loadAllCalories({bool showLoading = false}) async {
    if (showLoading) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final ProfileModel profile = await ProfileResolver().resolve();
      final allCalories = await calorieItemRepository.fetchAllByProfile(
        profile,
        orderBy: 'created_at DESC',
      );

      // Group by date
      final Map<DateTime, List<CalorieItemModel>> grouped = {};
      final Map<DateTime, _DaySummary> summaries = {};
      double total = 0;
      int itemCount = 0;

      for (final calorie in allCalories) {
        final dateKey = DateTime(
          calorie.createdAt.year,
          calorie.createdAt.month,
          calorie.createdAt.day,
        );

        if (!grouped.containsKey(dateKey)) {
          grouped[dateKey] = [];
          summaries[dateKey] = _DaySummary();
        }
        grouped[dateKey]!.add(calorie);
        summaries[dateKey]!.itemCount++;
        itemCount++;

        if (calorie.isEaten()) {
          total += calorie.value;
          summaries[dateKey]!.totalEaten += calorie.value;
          if (calorie.value > 0) {
            summaries[dateKey]!.positiveSum += calorie.value;
          } else {
            summaries[dateKey]!.negativeSum += calorie.value;
          }
        }
      }

      // Sort dates descending
      final sortedDates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

      if (mounted) {
        setState(() {
          _groupedCalories = grouped;
          _daySummaries = summaries;
          _sortedDates = sortedDates;
          _totalAllTime = total;
          _totalItems = itemCount;
          _isLoading = false;
          // Expand the first date by default only on initial load
          if (_isInitialLoad && sortedDates.isNotEmpty) {
            _expandedDates.add(sortedDates.first);
            _isInitialLoad = false;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading calories: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocListener<HomeBloc, AbstractHomeState>(
      listener: (context, state) {
        if (state is HomeFetched) {
          _loadAllCalories();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Calorie History'),
          elevation: 0,
          actions: [
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'expand_all') {
                  setState(() {
                    _expandedDates = Set.from(_sortedDates);
                  });
                } else if (value == 'collapse_all') {
                  setState(() {
                    _expandedDates.clear();
                  });
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'expand_all',
                  child: Row(
                    children: [
                      Icon(Icons.unfold_more, size: 20),
                      SizedBox(width: 12),
                      Text('Expand All'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'collapse_all',
                  child: Row(
                    children: [
                      Icon(Icons.unfold_less, size: 20),
                      SizedBox(width: 12),
                      Text('Collapse All'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _sortedDates.isEmpty
            ? _buildEmptyState()
            : _buildContent(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.restaurant_menu,
              size: 64,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No calories recorded yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start tracking your calories\nto see your history here',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        _buildSummaryCard(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadAllCalories,
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 24),
              itemCount: _sortedDates.length,
              itemBuilder: (context, index) {
                final date = _sortedDates[index];
                return _buildDateGroup(date);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard() {
    final totalDays = _sortedDates.length;
    final avgPerDay = totalDays > 0 ? _totalAllTime / totalDays : 0.0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor.withValues(alpha: 0.8),
            Theme.of(context).primaryColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem(
                icon: Icons.calendar_month,
                value: totalDays.toString(),
                label: 'Days Tracked',
              ),
              Container(
                height: 50,
                width: 1,
                color: Colors.white.withValues(alpha: 0.3),
              ),
              _buildSummaryItem(
                icon: Icons.local_fire_department,
                value: '${_totalAllTime.toStringAsFixed(0)}',
                label: 'Total kcal',
              ),
              Container(
                height: 50,
                width: 1,
                color: Colors.white.withValues(alpha: 0.3),
              ),
              _buildSummaryItem(
                icon: Icons.analytics_outlined,
                value: '${avgPerDay.toStringAsFixed(0)}',
                label: 'Avg/Day',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$_totalItems entries total',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildDateGroup(DateTime date) {
    final items = _groupedCalories[date] ?? [];
    final summary = _daySummaries[date]!;
    final isExpanded = _expandedDates.contains(date);
    final isToday = _isToday(date);
    final isYesterday = _isYesterday(date);

    String dateLabel;
    if (isToday) {
      dateLabel = 'Today';
    } else if (isYesterday) {
      dateLabel = 'Yesterday';
    } else {
      dateLabel = DateFormat('EEEE, MMM d, y').format(date);
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: isToday ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isToday
            ? BorderSide(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
          width: 2,
        )
            : BorderSide.none,
      ),
      child: Column(
        children: [
          // Date Header
          InkWell(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedDates.remove(date);
                } else {
                  _expandedDates.add(date);
                }
              });
            },
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(16),
              bottom: isExpanded ? Radius.zero : const Radius.circular(16),
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isToday
                    ? Theme.of(context).primaryColor.withValues(alpha: 0.05)
                    : null,
                borderRadius: BorderRadius.vertical(
                  top: const Radius.circular(16),
                  bottom: isExpanded ? Radius.zero : const Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  // Date Badge
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: isToday
                          ? LinearGradient(
                        colors: [
                          Theme.of(context).primaryColor,
                          Theme.of(context).primaryColor.withValues(alpha: 0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                          : null,
                      color: isToday ? null : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat('d').format(date),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isToday ? Colors.white : Colors.black87,
                          ),
                        ),
                        Text(
                          DateFormat('MMM').format(date).toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isToday
                                ? Colors.white.withValues(alpha: 0.9)
                                : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Day Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dateLabel,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight:
                            isToday ? FontWeight.bold : FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _buildStatChip(
                              '${summary.itemCount}',
                              'items',
                              Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            if (summary.positiveSum > 0)
                              _buildStatChip(
                                '+${summary.positiveSum.toStringAsFixed(0)}',
                                '',
                                DangerColor,
                              ),
                            if (summary.negativeSum < 0) ...[
                              const SizedBox(width: 4),
                              _buildStatChip(
                                summary.negativeSum.toStringAsFixed(0),
                                '',
                                SuccessColor,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Total Calories
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        summary.totalEaten.toStringAsFixed(0),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: summary.totalEaten > 2000
                              ? DangerColor
                              : summary.totalEaten > 1500
                              ? Colors.orange
                              : SuccessColor,
                        ),
                      ),
                      Text(
                        'kcal',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Expanded Items
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              children: [
                Container(
                  height: 1,
                  color: Colors.grey.shade200,
                ),
                ...items.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final isLast = index == items.length - 1;
                  return _buildCalorieItem(item, isLast);
                }),
              ],
            ),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$value${label.isNotEmpty ? ' $label' : ''}',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color.withValues(alpha: 0.8),
        ),
      ),
    );
  }

  Widget _buildCalorieItem(CalorieItemModel item, bool isLast) {
    return InkWell(
      onTap: () => _showItemOptions(item),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(
            bottom: BorderSide(
              color: Colors.grey.shade100,
            ),
          ),
        ),
        child: Opacity(
          opacity: item.isEaten() ? 1.0 : 0.5,
          child: Row(
            children: [
              // Time
              Container(
                width: 56,
                alignment: Alignment.center,
                child: Column(
                  children: [
                    Text(
                      DateFormat('HH:mm').format(item.createdAt),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    if (item.isEaten())
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: SuccessColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Eaten',
                          style: TextStyle(
                            fontSize: 9,
                            color: SuccessColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    else
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Planned',
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Color indicator
              Container(
                width: 4,
                height: 44,
                decoration: BoxDecoration(
                  color: item.value > 0 ? DangerLiteColor : SuccessColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              // Description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (item.description != null &&
                        item.description!.isNotEmpty)
                      Text(
                        item.description!,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      )
                    else
                      Text(
                        'No description',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade400,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Calories value
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: (item.value > 0 ? DangerColor : SuccessColor)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${item.value >= 0 ? '+' : ''}${item.value.toStringAsFixed(0)} kcal',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: item.value > 0 ? DangerColor : SuccessColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showItemOptions(CalorieItemModel item) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Item preview
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.local_fire_department,
                        color: item.value > 0 ? DangerColor : SuccessColor,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${item.value >= 0 ? '+' : ''}${item.value.toStringAsFixed(0)} kcal',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color:
                                item.value > 0 ? DangerColor : SuccessColor,
                              ),
                            ),
                            if (item.description != null)
                              Text(
                                item.description!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      Text(
                        DateFormat('MMM d, HH:mm').format(item.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.edit, color: Colors.blue, size: 20),
                  ),
                  title: const Text('Edit Entry'),
                  subtitle: const Text('Modify calories or description'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditCalorieItemScreen(item),
                      ),
                    ).then((_) => _loadAllCalories());
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (item.isEaten() ? Colors.orange : SuccessColor)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      item.isEaten() ? Icons.cancel : Icons.check_circle,
                      color: item.isEaten() ? Colors.orange : SuccessColor,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    item.isEaten() ? 'Mark as Not Eaten' : 'Mark as Eaten',
                  ),
                  subtitle: Text(
                    item.isEaten()
                        ? 'Remove from today\'s total'
                        : 'Add to today\'s total',
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    BlocProvider.of<HomeBloc>(context).add(
                      CalorieItemEatingEvent(item),
                    );
                    Future.delayed(const Duration(milliseconds: 300), () {
                      _loadAllCalories();
                    });
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: DangerColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child:
                    const Icon(Icons.delete, color: DangerColor, size: 20),
                  ),
                  title: const Text(
                    'Delete Entry',
                    style: TextStyle(color: DangerColor),
                  ),
                  subtitle: const Text('Permanently remove this entry'),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmDelete(item);
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmDelete(CalorieItemModel item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: DangerColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.delete_outline, color: DangerColor),
            ),
            const SizedBox(width: 12),
            const Text('Delete Entry'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete this ${item.value.toStringAsFixed(0)} kcal entry?\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              BlocProvider.of<HomeBloc>(context).add(
                RemovingCalorieItemEvent(item, [], () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Entry deleted successfully'),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  );
                  _loadAllCalories();
                }),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: DangerColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  bool _isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;
  }
}

class _DaySummary {
  double totalEaten = 0;
  double positiveSum = 0;
  double negativeSum = 0;
  int itemCount = 0;
}