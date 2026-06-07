import 'package:cat_calories_core/features/profile/domain/profile.dart';
import 'package:cat_calories/common/locator.dart';
import 'package:cat_calories_core/features/profile/domain/profile_repository_interface.dart';

final class ProfileSeeds {
  ProfileSeeds._();

  static const profileId = '00000000-0000-0000-0000-6c72ae642764';

  static ProfileRepositoryInterface get _repo =>
      locator.get<ProfileRepositoryInterface>();

  static Future<Profile> seed() async {
    final now = DateTime.now();
    final profile = Profile(
      id: profileId,
      name: 'Default Profile',
      wakingTimeSeconds: 16 * 60 * 60,
      caloriesLimitGoal: 2000,
      createdAt: now,
      updatedAt: now,
    );

    await _repo.insert(profile);
    return profile;
  }
}
