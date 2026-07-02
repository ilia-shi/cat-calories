import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'profile_input_field.dart';
import 'profile_settings_card.dart';

/// "Profile Information" card — currently just the profile-name field.
class ProfileInfoCard extends StatelessWidget {
  final TextEditingController nameController;
  final bool isDark;
  final Color primaryColor;

  const ProfileInfoCard({
    super.key,
    required this.nameController,
    required this.isDark,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return ProfileSettingsCard(
      isDark: isDark,
      child: ProfileInputField(
        controller: nameController,
        label: 'Profile Name',
        hint: 'Enter your name',
        icon: Icons.person_outline_rounded,
        isDark: isDark,
        primaryColor: primaryColor,
        textCapitalization: TextCapitalization.words,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter a profile name';
          }
          return null;
        },
      ),
    );
  }
}

/// "Daily Goals" card — daily calorie target, active-hours and currency fields.
class ProfileGoalsCard extends StatelessWidget {
  final TextEditingController calorieController;
  final TextEditingController wakingController;
  final TextEditingController currencyController;
  final bool isDark;
  final Color primaryColor;

  const ProfileGoalsCard({
    super.key,
    required this.calorieController,
    required this.wakingController,
    required this.currencyController,
    required this.isDark,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return ProfileSettingsCard(
      isDark: isDark,
      child: Column(
        children: [
          ProfileInputField(
            controller: calorieController,
            label: 'Daily Calorie Goal',
            hint: 'e.g., 2000',
            icon: Icons.local_fire_department_rounded,
            isDark: isDark,
            primaryColor: primaryColor,
            suffix: 'kCal',
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your calorie goal';
              }
              final parsed = double.tryParse(value);
              if (parsed == null || parsed <= 0) {
                return 'Please enter a valid number';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          ProfileInputField(
            controller: wakingController,
            label: 'Active Hours',
            hint: 'e.g., 16',
            icon: Icons.access_time_rounded,
            isDark: isDark,
            primaryColor: primaryColor,
            suffix: 'hours',
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            helperText: 'Hours you\'re typically awake per day',
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter waking hours';
              }
              final hours = int.tryParse(value);
              if (hours == null || hours < 1 || hours > 24) {
                return 'Please enter a value between 1-24';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          ProfileInputField(
            controller: currencyController,
            label: 'Default Currency',
            hint: 'e.g., EUR',
            icon: Icons.payments_outlined,
            isDark: isDark,
            primaryColor: primaryColor,
            textCapitalization: TextCapitalization.characters,
            helperText: 'Prefills the currency on product prices',
            validator: (value) {
              if (value != null &&
                  value.trim().isNotEmpty &&
                  value.trim().length != 3) {
                return 'Use a 3-letter code like EUR';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }
}
