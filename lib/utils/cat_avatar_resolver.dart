import 'package:cat_calories_core/features/profile/domain/profile.dart';
import 'package:flutter/widgets.dart';

class CatAvatarResolver {
  static AssetImage getImageByProfle(Profile profile) {
    final digit = (profile.id.hashCode.abs() % 10).toString();

    return AssetImage('images/cats/cat_face_0$digit.jpg');
  }
}
