import 'package:cat_calories/features/calorie_tracking/ui/calories_history.dart';
import 'package:cat_calories/features/dashboard/ui/tabs/main_info_tab.dart';
import 'package:cat_calories/features/dashboard/ui/tabs/products_tab.dart';
import 'package:cat_calories/features/dashboard/ui/tabs/tracking_tab.dart';
import 'package:cat_calories/features/dashboard/ui/widgets/home_bottom_nav.dart';
import 'package:flutter/material.dart';

final class HomeTab {
  const HomeTab({required this.navItem, required this.buildView});

  final HomeBottomNavItem navItem;
  final Widget Function() buildView;
}

final homeTabs = <HomeTab>[
  HomeTab(
    navItem: const HomeBottomNavItem(
      icon: Icons.restaurant_outlined,
      activeIcon: Icons.restaurant,
      label: 'Tracking',
    ),
    buildView: () => TrackingTab(),
  ),
  HomeTab(
    navItem: const HomeBottomNavItem(
      icon: Icons.inventory_2_outlined,
      activeIcon: Icons.inventory_2,
      label: 'Products',
    ),
    buildView: () => const ProductsTab(),
  ),
  HomeTab(
    navItem: const HomeBottomNavItem(
      icon: Icons.local_fire_department_outlined,
      activeIcon: Icons.local_fire_department,
      label: 'kCal',
    ),
    buildView: () => AllCaloriesHistoryScreen(),
  ),
  HomeTab(
    navItem: const HomeBottomNavItem(
      icon: Icons.info_outline,
      activeIcon: Icons.info,
      label: 'Info',
    ),
    buildView: () => MainInfoView(),
  ),
];
