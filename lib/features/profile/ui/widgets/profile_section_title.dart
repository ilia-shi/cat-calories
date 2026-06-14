import 'package:flutter/material.dart';

/// Small caption label shown above each settings card.
class ProfileSectionTitle extends StatelessWidget {
  final String title;
  final bool isDark;

  const ProfileSectionTitle(this.title, {super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.white54 : Colors.black54,
        letterSpacing: 0.5,
      ),
    );
  }
}
