import 'package:cat_calories/blocs/home/home_bloc.dart';
import 'package:cat_calories/blocs/home/home_event.dart';
import 'package:cat_calories/blocs/home/home_state.dart';
import 'package:cat_calories/blocs/theme/theme_cubit.dart';
import 'package:cat_calories/blocs/theme/theme_state.dart';
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

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
                        color: isDarkMode
                            ? Theme.of(context).colorScheme.surface
                            : Colors.white,
                      ),
                      accountName: Text(
                        state.activeProfile.name,
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      accountEmail: Text(
                        'Goal: ' +
                            state.activeProfile.caloriesLimitGoal.toString() +
                            ' kcal  / day',
                        style: TextStyle(
                          color: isDarkMode ? Colors.white70 : Colors.black54,
                        ),
                      ),
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
              // Theme Switcher
              BlocBuilder<ThemeCubit, ThemeState>(
                builder: (context, themeState) {
                  return ListTile(
                    leading: Icon(_getThemeIcon(themeState.themeMode)),
                    title: Text('Theme'),
                    subtitle: Text(themeState.themeModeLabel),
                    trailing: _buildThemeDropdown(context, themeState),
                    onTap: () {
                      _showThemeDialog(context, themeState);
                    },
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
              style: TextStyle(
                color: isDarkMode ? Colors.white54 : Colors.black54,
              ),
            ),
          ),
        ),
      ],
    );
  }

  IconData _getThemeIcon(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.system:
        return Icons.brightness_auto;
      case AppThemeMode.light:
        return Icons.light_mode;
      case AppThemeMode.dark:
        return Icons.dark_mode;
    }
  }

  Widget _buildThemeDropdown(BuildContext context, ThemeState themeState) {
    return PopupMenuButton<AppThemeMode>(
      icon: Icon(Icons.arrow_drop_down),
      onSelected: (AppThemeMode mode) {
        context.read<ThemeCubit>().setThemeMode(mode);
      },
      itemBuilder: (BuildContext context) {
        return AppThemeMode.values.map((AppThemeMode mode) {
          return PopupMenuItem<AppThemeMode>(
            value: mode,
            child: Row(
              children: [
                Icon(
                  _getThemeIcon(mode),
                  color: themeState.themeMode == mode
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                SizedBox(width: 12),
                Text(
                  _getThemeModeLabel(mode),
                  style: TextStyle(
                    fontWeight: themeState.themeMode == mode
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: themeState.themeMode == mode
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                ),
              ],
            ),
          );
        }).toList();
      },
    );
  }

  String _getThemeModeLabel(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.system:
        return 'System';
      case AppThemeMode.light:
        return 'Light';
      case AppThemeMode.dark:
        return 'Dark';
    }
  }

  void _showThemeDialog(BuildContext context, ThemeState themeState) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.palette),
              SizedBox(width: 12),
              Text('Choose Theme'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: AppThemeMode.values.map((AppThemeMode mode) {
              final isSelected = themeState.themeMode == mode;
              return ListTile(
                leading: Icon(
                  _getThemeIcon(mode),
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                title: Text(
                  _getThemeModeLabel(mode),
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                trailing: isSelected
                    ? Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary,
                )
                    : null,
                onTap: () {
                  context.read<ThemeCubit>().setThemeMode(mode);
                  Navigator.of(dialogContext).pop();
                },
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
}