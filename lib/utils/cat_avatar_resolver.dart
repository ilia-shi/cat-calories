import 'package:cat_calories/features/profile/domain/profile_model.dart';
import 'package:flutter/widgets.dart';

class CatAvatarResolver {
  static AssetImage getImageByProfle(ProfileModel profile) {
    final digit = (profile.id.hashCode.abs() % 10).toString();

    return AssetImage('images/cats/cat_face_0$digit.jpg');
  }
}
