import 'package:cat_calories/app/state/home_bloc.dart';
import 'package:cat_calories/app/state/home_event.dart';
import 'package:cat_calories/app/state/home_state.dart';
import 'package:cat_calories/features/profile/ui/widgets/edit_profile_app_bar.dart';
import 'package:cat_calories/features/profile/ui/widgets/profile_avatar_header.dart';
import 'package:cat_calories/features/profile/ui/widgets/profile_danger_zone.dart';
import 'package:cat_calories/features/profile/ui/widgets/profile_form_cards.dart';
import 'package:cat_calories/features/profile/ui/widgets/profile_section_title.dart';
import 'package:cat_calories/features/profile/ui/widgets/sync_settings_card.dart';
import 'package:cat_calories/features/profile/ui/widgets/web_server_settings_card.dart';
import 'package:cat_calories_core/features/profile/domain/profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class EditProfileScreen extends StatefulWidget {
  final Profile profile;

  const EditProfileScreen(this.profile, {super.key});

  @override
  EditProfileScreenState createState() => EditProfileScreenState();
}

class EditProfileScreenState extends State<EditProfileScreen>
    with SingleTickerProviderStateMixin {
  late TextEditingController _nameController;
  late TextEditingController _wakingTimeHours;
  late TextEditingController _caloriesLimitGoal;
  late TextEditingController _defaultCurrency;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final _formKey = GlobalKey<FormState>();
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(text: widget.profile.name);
    _wakingTimeHours = TextEditingController(
        text: widget.profile.getExpectedWakingDuration().inHours.toString());
    _caloriesLimitGoal =
        TextEditingController(text: widget.profile.caloriesLimitGoal.toString());
    _defaultCurrency =
        TextEditingController(text: widget.profile.defaultCurrency ?? '');

    // Track changes
    _nameController.addListener(_onFieldChanged);
    _wakingTimeHours.addListener(_onFieldChanged);
    _caloriesLimitGoal.addListener(_onFieldChanged);
    _defaultCurrency.addListener(_onFieldChanged);

    // Setup animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.forward();
  }

  void _onFieldChanged() {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _wakingTimeHours.dispose();
    _caloriesLimitGoal.dispose();
    _defaultCurrency.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    widget.profile.caloriesLimitGoal = double.parse(_caloriesLimitGoal.text);
    widget.profile.setExpectedWakingDuration(
        Duration(hours: int.parse(_wakingTimeHours.text)));
    widget.profile.name = _nameController.text;
    final currency = _defaultCurrency.text.trim().toUpperCase();
    widget.profile.defaultCurrency = currency.isEmpty ? null : currency;
    widget.profile.updatedAt = DateTime.now();

    BlocProvider.of<HomeBloc>(context).add(ProfileUpdatingEvent(widget.profile));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Text('Profile "${widget.profile.name}" saved'),
          ],
        ),
        backgroundColor: const Color(0xFF4CAF50),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: EditProfileAppBar(
        isDark: isDark,
        primaryColor: primaryColor,
        hasChanges: _hasChanges,
        onSave: _saveProfile,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ProfileAvatarHeader(
                    profile: widget.profile,
                    isDark: isDark,
                    primaryColor: primaryColor,
                  ),
                  const SizedBox(height: 32),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ProfileSectionTitle('Profile Information', isDark: isDark),
                        const SizedBox(height: 16),
                        ProfileInfoCard(
                          nameController: _nameController,
                          isDark: isDark,
                          primaryColor: primaryColor,
                        ),
                        const SizedBox(height: 28),
                        ProfileSectionTitle('Daily Goals', isDark: isDark),
                        const SizedBox(height: 16),
                        ProfileGoalsCard(
                          calorieController: _caloriesLimitGoal,
                          wakingController: _wakingTimeHours,
                          currencyController: _defaultCurrency,
                          isDark: isDark,
                          primaryColor: primaryColor,
                        ),
                        const SizedBox(height: 28),
                        ProfileSectionTitle('Data Sync', isDark: isDark),
                        const SizedBox(height: 16),
                        SyncSettingsCard(isDark: isDark, primaryColor: primaryColor),
                        const SizedBox(height: 28),
                        ProfileSectionTitle('Web Server', isDark: isDark),
                        const SizedBox(height: 16),
                        WebServerSettingsCard(
                            isDark: isDark, primaryColor: primaryColor),
                        const SizedBox(height: 32),
                        // Danger Zone — only when more than one profile exists.
                        BlocBuilder<HomeBloc, AbstractHomeState>(
                          builder: (context, state) {
                            if (state is HomeFetched &&
                                state.profiles.length > 1) {
                              return ProfileDangerZone(
                                profile: widget.profile,
                                state: state,
                                isDark: isDark,
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
