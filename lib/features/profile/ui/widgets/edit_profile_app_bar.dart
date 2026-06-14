import 'package:flutter/material.dart';

/// App bar for the edit-profile screen: a pill back button, centred title, and
/// a Save action that dims and disables itself until there are unsaved changes.
class EditProfileAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool isDark;
  final Color primaryColor;
  final bool hasChanges;
  final VoidCallback onSave;

  const EditProfileAppBar({
    super.key,
    required this.isDark,
    required this.primaryColor,
    required this.hasChanges,
    required this.onSave,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        'Edit Profile',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      centerTitle: true,
      actions: [
        AnimatedOpacity(
          opacity: hasChanges ? 1.0 : 0.5,
          duration: const Duration(milliseconds: 200),
          child: Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton.icon(
              onPressed: hasChanges ? onSave : null,
              icon: const Icon(Icons.check_rounded, size: 20),
              label: const Text(
                'Save',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              style: TextButton.styleFrom(
                foregroundColor: primaryColor,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
