import 'package:flutter/material.dart';

/// The rounded, shadowed surface shared by every settings section on the
/// edit-profile screen (profile info, goals, sync, web server).
class ProfileSettingsCard extends StatelessWidget {
  final bool isDark;
  final Widget child;
  final EdgeInsetsGeometry padding;

  const ProfileSettingsCard({
    super.key,
    required this.isDark,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}
