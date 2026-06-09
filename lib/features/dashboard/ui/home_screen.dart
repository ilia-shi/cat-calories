import 'dart:async';

import 'package:cat_calories/app/state/home_bloc.dart';
import 'package:cat_calories/app/state/home_event.dart';
import 'package:cat_calories/features/calorie_tracking/ui/calories_history.dart';
import 'package:cat_calories/features/dashboard/ui/app_bar.dart';
import 'package:cat_calories/features/dashboard/ui/tabs/main_info_tab.dart';
import 'package:cat_calories/features/dashboard/ui/tabs/products_tab.dart';
import 'package:cat_calories/features/dashboard/ui/tabs/tracking_tab.dart';
import 'package:cat_calories/features/dashboard/ui/widgets/app_drawer.dart';
import 'package:cat_calories/features/dashboard/ui/widgets/floating_action_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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

  @override
  Widget build(BuildContext context) {
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
            appBar: const HomeAppBar(),
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
