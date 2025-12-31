import 'package:cat_calories/blocs/home/home_bloc.dart';
import 'package:cat_calories/blocs/home/home_event.dart';
import 'package:cat_calories/blocs/home/home_state.dart';
import 'package:cat_calories/models/calorie_item_model.dart';
import 'package:cat_calories/screens/edit_calorie_item_screen.dart';
import 'package:cat_calories/ui/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class _ItemsGroup {
  String title;
  List<CalorieItemModel> items = [];

  _ItemsGroup({
    required this.title,
  });
}

class CalorieItemsView extends StatefulWidget {
  CalorieItemsView({Key? key}) : super(key: key);

  @override
  _CalorieItemsViewState createState() => _CalorieItemsViewState();
}

class _CalorieItemsViewState extends State<CalorieItemsView> {
  void _removeCalorieItem(
      CalorieItemModel calorieItem, List<CalorieItemModel> calorieItems) {
    BlocProvider.of<HomeBloc>(context)
        .add(RemovingCalorieItemEvent(calorieItem, calorieItems, () {
      final snackBar = SnackBar(
          content:
              Text('${calorieItem.value.toStringAsFixed(2)} kcal removed'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }));
  }

  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, AbstractHomeState>(
      builder: (context, state) {
        if (state is HomeFetchingInProgress) {
          return Center(
            child: CircularProgressIndicator(),
          );
        }
        if (state is HomeFetched) {
          final _calorieItems = state.periodCalorieItems;

          if (_calorieItems.length == 0) {
            return Center(
              child: Text('No calorie items'),
            );
          }

          final List<_ItemsGroup> groups = [];
          const int seconds = 3600;
          int groupIndex = 0;

          _calorieItems.sort((a, b) {
            return b.createdAt.compareTo(a.createdAt);
          });

          _calorieItems.asMap().forEach((int index, CalorieItemModel item) {
            if (!groups.asMap().containsKey(groupIndex)) {
              groups.insert(
                groupIndex,
                _ItemsGroup(title: groupIndex.toString())
                  ..title = groupIndex.toString(),
              );
            }

            groups[groupIndex].items.add(item);

            if (_calorieItems.asMap().containsKey(index + 1)) {
              final nextItem = _calorieItems[index + 1];
              final diff = item.createdAt.difference(nextItem.createdAt);

              if (diff.inSeconds >= seconds) {
                groupIndex++;
              }
            }
          });

          final List<Widget> viewItems = [];

          groups.asMap().forEach((int index, _ItemsGroup group) {
            viewItems.add(ListTile(
              contentPadding: EdgeInsets.fromLTRB(25, 5, 25, 5),
              title: Text(DateFormat('HH:mm, MMM d')
                  .format(group.items.first.createdAt)),
            ));

            group.items.forEach((CalorieItemModel calorieItem) {
              final description =
                  DateFormat('HH:mm').format(calorieItem.createdAt) +
                      (calorieItem.description == null
                          ? ''
                          : (', ' + calorieItem.description!.toString()));

              viewItems.add(
                // ListTile(title: Text(description)),
                  Opacity(
                    // key: Key(index.toString()),
                    opacity: calorieItem.isEaten() ? 1 : 0.3,
                    child: GestureDetector(
                      onDoubleTap: () {
                        BlocProvider.of<HomeBloc>(context)
                            .add(CalorieItemEatingEvent(calorieItem));
                      },
                      child: ListTile(
                        contentPadding: EdgeInsets.fromLTRB(25, 10, 25, 10),
                        title: Text(
                          calorieItem.value.toStringAsFixed(2) + ' kcal',
                          style: TextStyle(
                              color: (calorieItem.value > 0
                                  ? DangerColor
                                  : SuccessColor)),
                        ),
                        subtitle: Text(description),
                        // trailing: ReorderableDragStartListener(
                        //   index: index,
                        //   child: const Icon(Icons.drag_handle),
                        // ),
                        onTap: () {
                          showModalBottomSheet<dynamic>(
                              context: context,
                              isScrollControlled: true,
                              builder: (BuildContext context) {
                                return Wrap(
                                  children: <Widget>[
                                    ListTile(
                                      title: Text(calorieItem.isEaten()
                                          ? 'Set as not eaten'
                                          : 'Set as eaten'),
                                      onTap: () {
                                        BlocProvider.of<HomeBloc>(context).add(
                                            CalorieItemEatingEvent(calorieItem));
                                        Navigator.of(context).pop();
                                        ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Ok')));
                                      },
                                    ),
                                    ListTile(
                                      title: Text('Edit'),
                                      onTap: () {
                                        Navigator.of(context).pop();
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  EditCalorieItemScreen(
                                                      calorieItem)),
                                        );
                                      },
                                    ),
                                    ListTile(
                                      title: Text('Remove'),
                                      onTap: () {
                                        Navigator.of(context).pop();
                                        _removeCalorieItem(
                                            calorieItem, _calorieItems);
                                      },
                                    ),
                                  ],
                                );
                              });
                        },
                      ),
                    ),
                  )
              );
            });
          });

          return ListView(
            // key: Key(),
            padding: const EdgeInsets.all(8),
            children: viewItems,
          );

          return ReorderableListView.builder(
            itemBuilder: (context, int index) {
              final CalorieItemModel calorieItem = _calorieItems[index];

              final description =
                  DateFormat('HH:mm').format(calorieItem.createdAt) +
                      (calorieItem.description == null
                          ? ''
                          : (', ' + calorieItem.description!.toString()));

              return Opacity(
                key: Key(index.toString()),
                opacity: calorieItem.isEaten() ? 1 : 0.3,
                child: GestureDetector(
                  onDoubleTap: () {
                    BlocProvider.of<HomeBloc>(context)
                        .add(CalorieItemEatingEvent(calorieItem));
                  },
                  child: ListTile(
                    contentPadding: EdgeInsets.fromLTRB(25, 10, 25, 10),
                    title: Text(
                      calorieItem.value.toStringAsFixed(2) + ' kcal',
                      style: TextStyle(
                          color: (calorieItem.value > 0
                              ? DangerColor
                              : SuccessColor)),
                    ),
                    subtitle: Text(description),
                    trailing: ReorderableDragStartListener(
                      index: index,
                      child: const Icon(Icons.drag_handle),
                    ),
                    onTap: () {
                      showModalBottomSheet<dynamic>(
                          context: context,
                          isScrollControlled: true,
                          builder: (BuildContext context) {
                            return Wrap(
                              children: <Widget>[
                                ListTile(
                                  title: Text(calorieItem.isEaten()
                                      ? 'Set as not eaten'
                                      : 'Set as eaten'),
                                  onTap: () {
                                    BlocProvider.of<HomeBloc>(context).add(
                                        CalorieItemEatingEvent(calorieItem));
                                    Navigator.of(context).pop();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Ok')));
                                  },
                                ),
                                ListTile(
                                  title: Text('Edit'),
                                  onTap: () {
                                    Navigator.of(context).pop();
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              EditCalorieItemScreen(
                                                  calorieItem)),
                                    );
                                  },
                                ),
                                ListTile(
                                  title: Text('Remove'),
                                  onTap: () {
                                    Navigator.of(context).pop();
                                    _removeCalorieItem(
                                        calorieItem, _calorieItems);
                                  },
                                ),
                              ],
                            );
                          });
                    },
                  ),
                ),
              );
            },
            itemCount: _calorieItems.length,
            onReorder: (int oldIndex, int newIndex) {
              setState(() {
                if (oldIndex < newIndex) {
                  newIndex -= 1;
                }
                final item = _calorieItems.removeAt(oldIndex);
                _calorieItems.insert(newIndex, item);
                BlocProvider.of<HomeBloc>(context)
                    .add(CalorieItemListResortingEvent(_calorieItems));
              });
            },
          );
        }
        return Center(
          child: Text('Error'),
        );
      },
    );
  }
}
