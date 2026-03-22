import 'package:cat_calories/features/profile/domain/profile_model.dart';
import 'package:flutter/widgets.dart';

class CatAvatarResolver {
  static AssetImage getImageByProfle(ProfileModel profile) {
    String number = profile.id.toString().substring(profile.id.toString().length - 1);

    return AssetImage('images/cats/cat_face_0$number.jpg');
  }
}
