import 'package:cat_calories_core/features/profile/domain/profile.dart';
import 'package:cat_calories_core/features/profile/domain/profile_repository_interface.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileResolver {

  final locator = GetIt.instance;
  Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  static Profile? _activeProfile;
  late ProfileRepositoryInterface _profileRepository = locator.get<ProfileRepositoryInterface>();
  static const String activeProfileKey = 'active_profile';

  Future<Profile> resolve() async {
    print('[BOOT] ProfileResolver.resolve - start');
    SharedPreferences prefs = await _prefs;
    print('[BOOT] ProfileResolver.resolve - prefs loaded');

    if (_activeProfile == null) {
      final List<Profile> profiles = await _profileRepository.fetchAll();

      // Handle migration from int to string: old versions stored profile ID as int
      String? activeProfileId;
      try {
        activeProfileId = prefs.getString(activeProfileKey);
      } catch (_) {
        // Old value was stored as int, remove it and fall through to first profile
        await prefs.remove(activeProfileKey);
      }

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
          await prefs.setString(activeProfileKey, _activeProfile!.id!);
        }
      }
    }

    // Only create a default profile if there are truly no profiles at all
    if (_activeProfile == null) {
      final newProfile = Profile(
          id: null,
          name: "Default Profile",
          wakingTimeSeconds: 16 * 60 * 60,
          caloriesLimitGoal: 2000,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now());

      await _profileRepository.insert(newProfile);

      List<Profile> profiles = await _profileRepository.fetchAll();
      _activeProfile = profiles.first;

      // Save the new profile as active
      await prefs.setString(activeProfileKey, _activeProfile!.id!);
    }

    print('[BOOT] ProfileResolver.resolve - done, profile: ${_activeProfile!.name}');
    return _activeProfile!;
  }

  /// Clear the cached active profile.
  /// Call this when a profile is deleted to force re-resolution.
  static void clearCache() {
    _activeProfile = null;
  }

  /// Update the cached active profile.
  /// Call this when switching profiles.
  static void setActiveProfile(Profile profile) {
    _activeProfile = profile;
  }
}