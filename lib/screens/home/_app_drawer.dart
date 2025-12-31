import 'package:cat_calories/blocs/home/home_bloc.dart';
import 'package:cat_calories/blocs/home/home_event.dart';
import 'package:cat_calories/blocs/home/home_state.dart';
import 'package:cat_calories/models/profile_model.dart';
import 'package:cat_calories/screens/create_profile_screen.dart';
import 'package:cat_calories/screens/edit_profile_screen.dart';
import 'package:cat_calories/utils/cat_avatar_resolver.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cat_calories/screens/calories_history.dart';

class AppDrawer extends StatefulWidget {
  AppDrawer({Key? key}) : super(key: key);

  @override
  _AppDrawerState createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              BlocBuilder<HomeBloc, AbstractHomeState>(
                builder: (context, state) {
                  if (state is HomeFetched) {
                    return UserAccountsDrawerHeader(
                      decoration: BoxDecoration(
                        color: Colors.white,
                      ),
                      accountName: Text(state.activeProfile.name),
                      accountEmail: Text('Goal: ' +
                          state.activeProfile.caloriesLimitGoal.toString() +
                          ' kcal  / day'),
                      currentAccountPicture: CircleAvatar(
                        backgroundImage: CatAvatarResolver.getImageByProfle(
                            state.activeProfile),
                      ),
                    );
                  }

                  return Text('...');
                },
              ),
              BlocBuilder<HomeBloc, AbstractHomeState>(
                builder: (context, state) {
                  if (state is HomeFetched) {
                    return Column(
                      children: state.profiles.map((ProfileModel profile) {
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage:
                            CatAvatarResolver.getImageByProfle(profile),
                          ),
                          title: Text(profile.name),
                          onTap: () {
                            BlocProvider.of<HomeBloc>(context)
                                .add(ChangeProfileEvent(profile, {}));
                          },
                        );
                      }).toList(),
                    );
                  }

                  return ListTile(
                    title: Text('...'),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.add),
                title: Text('Create profile'),
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => CreateProfileScreen()));
                  // Navigator.pop(context);
                },
              ),
              Divider(),
              // Calorie History Link
              ListTile(
                leading: Icon(Icons.history),
                title: Text('Calorie History'),
                subtitle: Text('View all calories by date'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AllCaloriesHistoryScreen(),
                    ),
                  );
                },
              ),
              Divider(),
              BlocBuilder<HomeBloc, AbstractHomeState>(
                builder: (context, state) {
                  if (state is HomeFetched) {
                    return ListTile(
                      leading: Icon(Icons.settings),
                      title: Text('Profile settings'),
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    EditProfileScreen(state.activeProfile)));
                      },
                    );
                  }
                  return ListTile();
                },
              ),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.fromLTRB(10, 10, 10, 10),
          child: SizedBox(
            child: Text(
              'Version: 1.2',
            ),
          ),
        ),
      ],
    );
  }
}