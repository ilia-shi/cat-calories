import 'package:cat_calories/models/profile_model.dart';
import 'package:cat_calories/repositories/profile_repository.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileResolver {

  final locator = GetIt.instance;
  Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  static ProfileModel? _activeProfile;
  late ProfileRepository _profileRepository = locator.get<ProfileRepository>();
  static const String activeProfileKey = 'active_profile';

  Future<ProfileModel> resolve() async {
    SharedPreferences prefs = await _prefs;

    if (_activeProfile == null) {
      final List<ProfileModel> profiles = await _profileRepository.fetchAll();

      final int? activeProfileId = prefs.getInt(activeProfileKey);

      if (activeProfileId == null) {
        // No saved preference - use first profile if available
        _activeProfile = profiles.isNotEmpty ? profiles.first : null;
      } else {
        // Try to find the saved profile
        for (final profile in profiles) {
          if (profile.id == activeProfileId) {
            _activeProfile = profile;
            break;
          }
        }

        // If saved profile wasn't found (e.g., it was deleted),
        // fall back to first available profile instead of creating a new one
        if (_activeProfile == null && profiles.isNotEmpty) {
          _activeProfile = profiles.first;
          // Update SharedPreferences to the new active profile
          await prefs.setInt(activeProfileKey, _activeProfile!.id!);
        }
      }
    }

    // Only create a default profile if there are truly no profiles at all
    if (_activeProfile == null) {
      final newProfile = ProfileModel(
          id: null,
          name: "Default Profile",
          wakingTimeSeconds: 16 * 60 * 60,
          caloriesLimitGoal: 2000,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now());

      await _profileRepository.insert(newProfile);

      List<ProfileModel> profiles = await _profileRepository.fetchAll();
      _activeProfile = profiles.first;

      // Save the new profile as active
      await prefs.setInt(activeProfileKey, _activeProfile!.id!);
    }

    return _activeProfile!;
  }

  /// Clear the cached active profile.
  /// Call this when a profile is deleted to force re-resolution.
  static void clearCache() {
    _activeProfile = null;
  }

  /// Update the cached active profile.
  /// Call this when switching profiles.
  static void setActiveProfile(ProfileModel profile) {
    _activeProfile = profile;
  }
}