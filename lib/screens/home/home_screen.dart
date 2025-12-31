import 'dart:async';

import 'package:cat_calories/models/waking_period_model.dart';
import 'package:cat_calories/screens/calories/day_calories_page.dart';
import 'package:cat_calories/screens/create_food_intake_screen.dart';
import 'package:cat_calories/screens/create_product_screen.dart';
import 'package:cat_calories/screens/home/widgets/app_drawer.dart';
import 'package:cat_calories/screens/home/tabs/calorie_items_tab.dart';
import 'package:cat_calories/screens/home/tabs/days_tab.dart';
import 'package:cat_calories/screens/home/tabs/periods_tab.dart';
import 'package:cat_calories/screens/home/widgets/floating_action_button.dart';
import 'package:cat_calories/ui/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cat_calories/blocs/home/home_bloc.dart';
import 'package:cat_calories/blocs/home/home_event.dart';
import 'package:cat_calories/blocs/home/home_state.dart';
import 'package:cat_calories/models/calorie_item_model.dart';
import 'tabs/equalization_stats_tab.dart';
import 'tabs/main_info_tab.dart';

class HomeScreen extends StatefulWidget {
  HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  List<CalorieItemModel> _calorieItems = [];
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

  @override
  Widget build(BuildContext context) {
    BlocProvider.of<HomeBloc>(context)
        .add(CalorieItemListFetchingInProgressEvent());

    const menuItems = [
      PopupMenuItem<String>(
        value: 'calories',
        child: ListTile(title: Text('Calories')),
      ),
      PopupMenuItem<String>(
        value: 'create_product',
        child: ListTile(title: Text('Create product')),
      ),
      PopupMenuItem<String>(
        value: 'products',
        child: ListTile(title: Text('Products')),
      ),
      PopupMenuItem<String>(
        value: 'create_food_intake',
        child: ListTile(title: Text('Create food intake')),
      ),
    ];

    return Scaffold(
      body: Scaffold(
        body: DefaultTabController(
          length: 5,
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
                      onSelected: (String value) {
                        if (value == 'create_product') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    CreateProductScreen(state.activeProfile)),
                          );
                        } else if (value == 'calories') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) {
                              return DayCaloriesPage(state.startDate);
                            }),
                          );
                        } else if (value == 'products') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  CreateFoodIntakeScreen(state.activeProfile),
                            ),
                          );
                        }
                      },
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
                tabs: [
                  Tab(text: 'Stats'),  // NEW - rename or add
                  Tab(text: 'Info'),
                  Tab(text: 'kCal'),
                  Tab(text: 'Periods'),
                  Tab(text: 'Days'),
                ],
              ),

              // Home Screen
              title: BlocBuilder<HomeBloc, AbstractHomeState>(
                builder: (context, state) {
                  if (state is HomeFetched) {
                    if (state.currentWakingPeriod is WakingPeriodModel) {
                      return Text(
                        '${state.getPeriodCaloriesEatenSum().round()} / ${state.currentWakingPeriod!.caloriesLimitGoal} kCal',
                        style: TextStyle(
                          color: (state.getPeriodCaloriesEatenSum() >
                                  state.currentWakingPeriod!.caloriesLimitGoal
                              ? DangerColor
                              : SuccessColor),
                        ),
                      );
                    }

                    return Text(
                      'For current period: ${state.getPeriodCaloriesEatenSum().round()} kCal',
                    );
                  }

                  return Text('...');
                },
              ),
            ),
            body: TabBarView(
              children: [
                EqualizationStatsView(),
                MainInfoView(),
                CalorieItemsView(),
                WakingPeriodsView(),
                DaysView(),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: const HomeFloatingActionButton(),
    );
  }
}
