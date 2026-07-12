import 'package:cat_calories/app/state/home_bloc.dart';
import 'package:cat_calories/app/state/home_event.dart';
import 'package:cat_calories/features/calorie_tracking/ui/calories_history.dart';
import 'package:cat_calories/features/dashboard/ui/app_bar.dart';
import 'package:cat_calories/features/dashboard/ui/tabs/main_info_tab.dart';
import 'package:cat_calories/features/dashboard/ui/tabs/products_tab.dart';
import 'package:cat_calories/features/dashboard/ui/tabs/tracking_tab.dart';
import 'package:cat_calories/features/dashboard/ui/widgets/app_drawer.dart';
import 'package:cat_calories/features/dashboard/ui/widgets/floating_action_button.dart';
import 'package:cat_calories/features/dashboard/ui/widgets/home_bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomeScreen extends StatefulWidget {
  HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  static const _navItems = <HomeBottomNavItem>[
    HomeBottomNavItem(
      icon: Icons.restaurant_outlined,
      activeIcon: Icons.restaurant,
      label: 'Tracking',
    ),
    HomeBottomNavItem(
      icon: Icons.inventory_2_outlined,
      activeIcon: Icons.inventory_2,
      label: 'Products',
    ),
    HomeBottomNavItem(
      icon: Icons.local_fire_department_outlined,
      activeIcon: Icons.local_fire_department,
      label: 'kCal',
    ),
    HomeBottomNavItem(
      icon: Icons.info_outline,
      activeIcon: Icons.info,
      label: 'Info',
    ),
  ];

  TextEditingController _calorieItemController = TextEditingController();

  late final TabController _tabController;

  /// Built once — recreating these every build (which the old 5s timer forced)
  /// churned all four tabs.
  late final List<Widget> _tabViews;

  /// Merged rebuild trigger handed to the bottom nav so only its dynamic parts
  /// repaint per frame.
  late final Listenable _navListenable;

  /// Drives how collapsed the bottom nav is: 0 = expanded (labels shown),
  /// 1 = collapsed (labels hidden, icons shrunk).
  late final AnimationController _navCollapseController;

  /// Drives the sliding pill indicator. [_indicatorPosition] interpolates
  /// between the previous and the current item index as this runs.
  late final AnimationController _indicatorController;
  late Animation<double> _indicatorPosition;

  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _calorieItemController = TextEditingController();

    _tabController = TabController(length: _navItems.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging &&
          _tabController.index != _currentIndex) {
        setState(() {
          _currentIndex = _tabController.index;
          _indicatorPosition = AlwaysStoppedAnimation(_currentIndex.toDouble());
        });
      }
    });

    _navCollapseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    _indicatorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _indicatorPosition = AlwaysStoppedAnimation(_currentIndex.toDouble());

    _navListenable = Listenable.merge([
      _navCollapseController,
      _indicatorController,
      _tabController.animation!,
    ]);

    _tabViews = [
      TrackingTab(),
      const ProductsTab(),
      AllCaloriesHistoryScreen(),
      MainInfoView(),
    ];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      BlocProvider.of<HomeBloc>(context)
          .add(CalorieItemListFetchingInProgressEvent());
    });

    _calorieItemController.addListener(() {
      BlocProvider.of<HomeBloc>(context)
          .add(CaloriePreparedEvent(_calorieItemController.text));
    });
  }

  @override
  void dispose() {
    _calorieItemController.dispose();
    _tabController.dispose();
    _navCollapseController.dispose();
    _indicatorController.dispose();

    super.dispose();
  }

  _HomeScreenState();

  bool _handleScroll(UserScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) {
      return false;
    }
    switch (notification.direction) {
      case ScrollDirection.reverse:
        _navCollapseController.forward();
        break;
      case ScrollDirection.forward:
        _navCollapseController.reverse();
        break;
      case ScrollDirection.idle:
        break;
    }
    return false;
  }

  void _onNavTap(int index) {
    if (index == _currentIndex) {
      return;
    }
    _animateIndicatorTo(_currentIndex, index);
    setState(() => _currentIndex = index);
    _tabController.animateTo(index);
  }

  void _animateIndicatorTo(int from, int to) {
    _indicatorPosition = Tween<double>(
      begin: from.toDouble(),
      end: to.toDouble(),
    ).animate(
      CurvedAnimation(parent: _indicatorController, curve: Curves.easeOutCubic),
    );
    _indicatorController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawerScrimColor: Colors.transparent,
      drawer: const HomeAppDrawer(),
      extendBody: true,
      // Isolate the body (which holds three frosted blurs) as its own layer so
      // the sliding drawer — itself a moving blur — samples a cached raster
      // instead of forcing those blurs to re-run every drawer-animation frame.
      body: RepaintBoundary(
        child: NotificationListener<UserScrollNotification>(
          onNotification: _handleScroll,
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverPersistentHeader(
                pinned: true,
                delegate: HomeHeaderDelegate(
                  topPadding: MediaQuery.of(context).padding.top,
                ),
              ),
            ],
            body: TabBarView(
              controller: _tabController,
              // Tabs switch via the bottom nav only; no horizontal swipe, so it
              // can't fight inner horizontal scrollables (product chips, sliders)
              // or build the neighbour tab mid-drag.
              physics: const NeverScrollableScrollPhysics(),
              children: _tabViews,
            ),
          ),
        ),
      ),
      bottomNavigationBar: HomeBottomNav(
        animation: _navListenable,
        position: () => _tabController.indexIsChanging
            ? _indicatorPosition.value
            : _tabController.animation!.value,
        collapse: () => _navCollapseController.value,
        onTap: _onNavTap,
        items: _navItems,
      ),
      floatingActionButton: const HomeFloatingActionButton(),
    );
  }
}
