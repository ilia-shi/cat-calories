import 'package:cat_calories/app/state/home_bloc.dart';
import 'package:cat_calories/app/state/home_event.dart';
import 'package:cat_calories/features/dashboard/ui/app_bar.dart';
import 'package:cat_calories/features/dashboard/ui/home_tabs.dart';
import 'package:cat_calories/features/dashboard/ui/widgets/app_drawer.dart';
import 'package:cat_calories/features/dashboard/ui/widgets/floating_action_button.dart';
import 'package:cat_calories/features/dashboard/ui/widgets/home_bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

final class HomeScreen extends StatefulWidget {
  HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

final class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  static final _navItems = [for (final tab in homeTabs) tab.navItem];

  TextEditingController _calorieItemController = TextEditingController();

  late final TabController _tabController;
  late final List<Widget> _tabViews;
  late final Listenable _navListenable;
  late final AnimationController _navCollapseController;
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

    _tabViews = [for (final tab in homeTabs) tab.buildView()];

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
