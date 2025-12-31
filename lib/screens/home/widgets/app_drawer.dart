import 'package:cat_calories/blocs/home/home_bloc.dart';
import 'package:cat_calories/blocs/home/home_event.dart';
import 'package:cat_calories/blocs/home/home_state.dart';
import 'package:cat_calories/blocs/theme/theme_cubit.dart';
import 'package:cat_calories/blocs/theme/theme_state.dart';
import 'package:cat_calories/models/profile_model.dart';
import 'package:cat_calories/screens/calories_history.dart';
import 'package:cat_calories/screens/create_profile_screen.dart';
import 'package:cat_calories/screens/edit_profile_screen.dart';
import 'package:cat_calories/utils/cat_avatar_resolver.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomeAppDrawer extends StatelessWidget {
  const HomeAppDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: const [
                _DrawerHeader(),
                _ProfilesList(),
                _CreateProfileTile(),
                Divider(),
                _CalorieHistoryTile(),
                Divider(),
                _ThemeSwitcherTile(),
                Divider(),
                _ProfileSettingsTile(),
              ],
            ),
          ),
          const _VersionFooter(),
        ],
      ),
    );
  }
}

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader();

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<HomeBloc, AbstractHomeState>(
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
              'Goal: ${state.activeProfile.caloriesLimitGoal.toStringAsFixed(0)} kcal / day',
              style: TextStyle(
                color: isDarkMode ? Colors.white70 : Colors.black54,
              ),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundImage:
              CatAvatarResolver.getImageByProfle(state.activeProfile),
            ),
          );
        }

        return const UserAccountsDrawerHeader(
          accountName: Text('Loading...'),
          accountEmail: Text(''),
        );
      },
    );
  }
}

class _ProfilesList extends StatelessWidget {
  const _ProfilesList();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, AbstractHomeState>(
      builder: (context, state) {
        if (state is HomeFetched) {
          return Column(
            children: state.profiles.map((ProfileModel profile) {
              final isActive = profile.id == state.activeProfile.id;

              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: CatAvatarResolver.getImageByProfle(profile),
                ),
                title: Text(profile.name),
                trailing: isActive
                    ? Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary,
                )
                    : null,
                selected: isActive,
                onTap: () {
                  if (!isActive) {
                    context.read<HomeBloc>().add(ChangeProfileEvent(profile, () {}));
                  }
                  Navigator.of(context).pop();
                },
              );
            }).toList(),
          );
        }

        return const ListTile(
          title: Text('Loading profiles...'),
        );
      },
    );
  }
}

class _CreateProfileTile extends StatelessWidget {
  const _CreateProfileTile();

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.add),
      title: const Text('Create profile'),
      onTap: () {
        Navigator.of(context).pop();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => CreateProfileScreen()),
        );
      },
    );
  }
}

class _CalorieHistoryTile extends StatelessWidget {
  const _CalorieHistoryTile();

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.history),
      title: const Text('Calorie History'),
      subtitle: const Text('View all calories by date'),
      onTap: () {
        Navigator.of(context).pop();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AllCaloriesHistoryScreen(),
          ),
        );
      },
    );
  }
}

class _ThemeSwitcherTile extends StatelessWidget {
  const _ThemeSwitcherTile();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, themeState) {
        return ListTile(
          leading: Icon(_getThemeIcon(themeState.themeMode)),
          title: const Text('Theme'),
          subtitle: Text(themeState.themeModeLabel),
          trailing: _ThemeDropdownButton(currentMode: themeState.themeMode),
          onTap: () => _showThemeDialog(context, themeState),
        );
      },
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

  void _showThemeDialog(BuildContext context, ThemeState themeState) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Row(
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
              child: const Text('Cancel'),
            ),
          ],
        );
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
}

class _ThemeDropdownButton extends StatelessWidget {
  final AppThemeMode currentMode;

  const _ThemeDropdownButton({required this.currentMode});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<AppThemeMode>(
      icon: const Icon(Icons.arrow_drop_down),
      onSelected: (AppThemeMode mode) {
        context.read<ThemeCubit>().setThemeMode(mode);
      },
      itemBuilder: (BuildContext context) {
        return AppThemeMode.values.map((AppThemeMode mode) {
          final isSelected = currentMode == mode;
          return PopupMenuItem<AppThemeMode>(
            value: mode,
            child: Row(
              children: [
                Icon(
                  _getThemeIcon(mode),
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                const SizedBox(width: 12),
                Text(
                  _getThemeModeLabel(mode),
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected
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
}

class _ProfileSettingsTile extends StatelessWidget {
  const _ProfileSettingsTile();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, AbstractHomeState>(
      builder: (context, state) {
        if (state is HomeFetched) {
          return ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Profile settings'),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditProfileScreen(state.activeProfile),
                ),
              );
            },
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _VersionFooter extends StatelessWidget {
  const _VersionFooter();

  static const String _appVersion = '1.2';

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Text(
        'Version: $_appVersion',
        style: TextStyle(
          color: isDarkMode ? Colors.white54 : Colors.black54,
          fontSize: 12,
        ),
      ),
    );
  }
}