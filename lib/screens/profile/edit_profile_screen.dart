import 'package:cat_calories/blocs/home/home_bloc.dart';
import 'package:cat_calories/blocs/home/home_event.dart';
import 'package:cat_calories/blocs/home/home_state.dart';
import 'package:cat_calories/features/profile/domain/profile_model.dart';
import 'package:cat_calories/service/screen_energy_service.dart';
import 'package:cat_calories/service/sync_service.dart';
import 'package:cat_calories/service/web_server_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

class EditProfileScreen extends StatefulWidget {
  final ProfileModel profile;

  const EditProfileScreen(this.profile, {super.key});

  @override
  EditProfileScreenState createState() => EditProfileScreenState();
}

class EditProfileScreenState extends State<EditProfileScreen>
    with SingleTickerProviderStateMixin {
  late TextEditingController _nameController;
  late TextEditingController _wakingTimeHours;
  late TextEditingController _caloriesLimitGoal;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final _formKey = GlobalKey<FormState>();
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(text: widget.profile.name);
    _wakingTimeHours = TextEditingController(
        text: widget.profile.getExpectedWakingDuration().inHours.toString());
    _caloriesLimitGoal =
        TextEditingController(text: widget.profile.caloriesLimitGoal.toString());

    // Track changes
    _nameController.addListener(_onFieldChanged);
    _wakingTimeHours.addListener(_onFieldChanged);
    _caloriesLimitGoal.addListener(_onFieldChanged);

    // Setup animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
        );

    _animationController.forward();
  }

  void _onFieldChanged() {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _wakingTimeHours.dispose();
    _caloriesLimitGoal.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    if (!_formKey.currentState!.validate()) return;

    widget.profile.caloriesLimitGoal = double.parse(_caloriesLimitGoal.text);
    widget.profile.setExpectedWakingDuration(
        Duration(hours: int.parse(_wakingTimeHours.text)));
    widget.profile.name = _nameController.text;
    widget.profile.updatedAt = DateTime.now();

    BlocProvider.of<HomeBloc>(context).add(ProfileUpdatingEvent(widget.profile));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Text('Profile "${widget.profile.name}" saved'),
          ],
        ),
        backgroundColor: const Color(0xFF4CAF50),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );

    Navigator.of(context).pop();
  }

  void _showDeleteConfirmation(HomeFetched state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (bottomSheetContext) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.red,
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Delete Profile?',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'This will permanently delete "${widget.profile.name}" and all associated data. This action cannot be undone.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.color
                      ?.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(bottomSheetContext),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(
                          color: Theme.of(context).dividerColor,
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        BlocProvider.of<HomeBloc>(context)
                            .add(ProfileDeletingEvent(widget.profile));

                        Navigator.pop(bottomSheetContext);
                        Navigator.of(context).pop();

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(Icons.delete, color: Colors.white, size: 20),
                                const SizedBox(width: 12),
                                Text('Profile "${state.activeProfile.name}" deleted'),
                              ],
                            ),
                            backgroundColor: Colors.red,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            margin: const EdgeInsets.all(16),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Delete',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: MediaQuery.of(bottomSheetContext).padding.bottom),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
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
            opacity: _hasChanges ? 1.0 : 0.5,
            duration: const Duration(milliseconds: 200),
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: TextButton.icon(
                onPressed: _hasChanges ? _saveProfile : null,
                icon: const Icon(Icons.check_rounded, size: 20),
                label: const Text(
                  'Save',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Avatar Section
                  _buildAvatarSection(isDark, primaryColor),

                  const SizedBox(height: 32),

                  // Form Fields Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('Profile Information', isDark),
                        const SizedBox(height: 16),
                        _buildFormCard(isDark, primaryColor),

                        const SizedBox(height: 28),

                        _buildSectionTitle('Daily Goals', isDark),
                        const SizedBox(height: 16),
                        _buildGoalsCard(isDark, primaryColor),

                        const SizedBox(height: 28),

                        _buildSectionTitle('Data Sync', isDark),
                        const SizedBox(height: 16),
                        _SyncSettingsCard(isDark: isDark, primaryColor: primaryColor),

                        const SizedBox(height: 28),

                        _buildSectionTitle('Web Server', isDark),
                        const SizedBox(height: 16),
                        _WebServerSettingsCard(isDark: isDark, primaryColor: primaryColor),

                        const SizedBox(height: 32),

                        // Danger Zone
                        BlocBuilder<HomeBloc, AbstractHomeState>(
                          builder: (context, state) {
                            if (state is HomeFetched && state.profiles.length > 1) {
                              return _buildDangerZone(isDark, state);
                            }
                            return const SizedBox.shrink();
                          },
                        ),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarSection(bool isDark, Color primaryColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          // Avatar with gradient ring
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  primaryColor,
                  primaryColor.withOpacity(0.6),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
              ),
              child: Center(
                child: Text(
                  _getInitials(widget.profile.name),
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.profile.name,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Member since ${_formatDate(widget.profile.createdAt)}',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white54 : Colors.black45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
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

  Widget _buildFormCard(bool isDark, Color primaryColor) {
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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildInputField(
              controller: _nameController,
              label: 'Profile Name',
              hint: 'Enter your name',
              icon: Icons.person_outline_rounded,
              isDark: isDark,
              primaryColor: primaryColor,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a profile name';
                }
                return null;
              },
              textCapitalization: TextCapitalization.words,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalsCard(bool isDark, Color primaryColor) {
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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildInputField(
              controller: _caloriesLimitGoal,
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
            _buildInputField(
              controller: _wakingTimeHours,
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
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDark,
    required Color primaryColor,
    String? suffix,
    String? helperText,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          textCapitalization: textCapitalization,
          validator: validator,
          style: TextStyle(
            fontSize: 16,
            color: isDark ? Colors.white : Colors.black87,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: isDark ? Colors.white38 : Colors.black38,
            ),
            prefixIcon: Container(
              margin: const EdgeInsets.only(right: 12),
              child: Icon(
                icon,
                color: primaryColor,
                size: 22,
              ),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 48),
            suffixText: suffix,
            suffixStyle: TextStyle(
              color: isDark ? Colors.white54 : Colors.black45,
              fontWeight: FontWeight.w500,
            ),
            filled: true,
            fillColor: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.grey.withOpacity(0.08),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: primaryColor, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
        if (helperText != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 14,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
              const SizedBox(width: 6),
              Text(
                helperText,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildDangerZone(bool isDark, HomeFetched state) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(isDark ? 0.1 : 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.red.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.red.shade400,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Danger Zone',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.red.shade400,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showDeleteConfirmation(state),
                icon: const Icon(Icons.delete_outline_rounded, size: 20),
                label: const Text('Delete this profile'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(color: Colors.red.withOpacity(0.5)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}

class _WebServerSettingsCard extends StatefulWidget {
  final bool isDark;
  final Color primaryColor;

  const _WebServerSettingsCard({
    required this.isDark,
    required this.primaryColor,
  });

  @override
  State<_WebServerSettingsCard> createState() => _WebServerSettingsCardState();
}

class _WebServerSettingsCardState extends State<_WebServerSettingsCard> {
  final _screenEnergy = GetIt.instance.get<WebServerService>().screenEnergy;
  int _selectedMinutes = ScreenEnergyService.defaultTimeoutMinutes;
  int _selectedDimMinutes = ScreenEnergyService.defaultDimMinutes;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final minutes = await _screenEnergy.getTimeoutMinutes();
    final dimMinutes = await _screenEnergy.getDimTimeoutMinutes();
    if (mounted) {
      setState(() {
        _selectedMinutes = minutes;
        _selectedDimMinutes = dimMinutes;
      });
    }
  }

  String _formatTimeout(int minutes) {
    if (minutes == 0) return 'Never';
    if (minutes == 1) return '1 minute';
    return '$minutes minutes';
  }

  String _formatDimTimeout(int minutes) {
    if (minutes == -1) return 'Default';
    if (minutes == 0) return 'Never';
    if (minutes == 1) return '1 minute';
    return '$minutes minutes';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: widget.isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: widget.isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Screen timeout',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: widget.isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: widget.isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.grey.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _selectedMinutes,
                  isExpanded: true,
                  icon: Icon(
                    Icons.arrow_drop_down_rounded,
                    color: widget.isDark ? Colors.white54 : Colors.black45,
                  ),
                  dropdownColor: widget.isDark ? const Color(0xFF2A2A2A) : Colors.white,
                  style: TextStyle(
                    fontSize: 16,
                    color: widget.isDark ? Colors.white : Colors.black87,
                  ),
                  items: ScreenEnergyService.timeoutOptions.map((minutes) {
                    return DropdownMenuItem<int>(
                      value: minutes,
                      child: Row(
                        children: [
                          Icon(
                            minutes == 0 ? Icons.visibility : Icons.timer_outlined,
                            size: 18,
                            color: widget.primaryColor,
                          ),
                          const SizedBox(width: 12),
                          Text(_formatTimeout(minutes)),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _selectedMinutes = value);
                    _screenEnergy.setTimeoutMinutes(value);
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 14,
                  color: widget.isDark ? Colors.white38 : Colors.black38,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Turn off screen after inactivity while the web server is running',
                    style: TextStyle(
                      fontSize: 12,
                      color: widget.isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Dim brightness',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: widget.isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: widget.isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.grey.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _selectedDimMinutes,
                  isExpanded: true,
                  icon: Icon(
                    Icons.arrow_drop_down_rounded,
                    color: widget.isDark ? Colors.white54 : Colors.black45,
                  ),
                  dropdownColor: widget.isDark ? const Color(0xFF2A2A2A) : Colors.white,
                  style: TextStyle(
                    fontSize: 16,
                    color: widget.isDark ? Colors.white : Colors.black87,
                  ),
                  items: ScreenEnergyService.dimTimeoutOptions.map((minutes) {
                    return DropdownMenuItem<int>(
                      value: minutes,
                      child: Row(
                        children: [
                          Icon(
                            minutes == 0 ? Icons.brightness_high : Icons.brightness_low,
                            size: 18,
                            color: widget.primaryColor,
                          ),
                          const SizedBox(width: 12),
                          Text(_formatDimTimeout(minutes)),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _selectedDimMinutes = value);
                    _screenEnergy.setDimTimeoutMinutes(value);
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 14,
                  color: widget.isDark ? Colors.white38 : Colors.black38,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Reduce screen brightness before turning off. Default uses device screen timeout.',
                    style: TextStyle(
                      fontSize: 12,
                      color: widget.isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SyncSettingsCard extends StatefulWidget {
  final bool isDark;
  final Color primaryColor;

  const _SyncSettingsCard({
    required this.isDark,
    required this.primaryColor,
  });

  @override
  State<_SyncSettingsCard> createState() => _SyncSettingsCardState();
}

class _SyncSettingsCardState extends State<_SyncSettingsCard> {
  final _syncService = GetIt.instance.get<SyncService>();
  final _serverUrlController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _syncEnabled = false;
  bool _isLoggingIn = false;
  bool _isSyncing = false;
  String? _loginError;
  String? _syncStatus;
  bool _hasToken = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final enabled = await _syncService.isEnabled;
    final url = await _syncService.serverUrl;
    final tok = await _syncService.token;
    if (mounted) {
      setState(() {
        _syncEnabled = enabled;
        _serverUrlController.text = url;
        _hasToken = tok.isNotEmpty;
      });
    }
  }

  Future<void> _doLogin() async {
    final url = _serverUrlController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (url.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() => _loginError = 'All fields are required');
      return;
    }

    setState(() {
      _isLoggingIn = true;
      _loginError = null;
    });

    final token = await _syncService.login(url, email, password);

    if (!mounted) return;

    if (token != null) {
      await _syncService.setEnabled(true);
      setState(() {
        _isLoggingIn = false;
        _syncEnabled = true;
        _hasToken = true;
        _emailController.clear();
        _passwordController.clear();
      });
      _doSync();
    } else {
      setState(() {
        _isLoggingIn = false;
        _loginError = 'Invalid credentials or server unreachable';
      });
    }
  }

  Future<void> _doSync() async {
    setState(() {
      _isSyncing = true;
      _syncStatus = null;
    });

    final success = await _syncService.sync();

    if (!mounted) return;

    setState(() {
      _isSyncing = false;
      _syncStatus = success ? 'Sync completed' : 'Sync failed';
    });
  }

  Future<void> _reconnect() async {
    setState(() {
      _isSyncing = true;
      _syncStatus = null;
    });

    final success = await _syncService.reconnect();

    if (!mounted) return;

    if (success) {
      await _syncService.setEnabled(true);
      setState(() {
        _isSyncing = false;
        _syncEnabled = true;
        _hasToken = true;
      });
      _doSync();
    } else {
      setState(() {
        _isSyncing = false;
        _syncStatus = 'Reconnect failed: server unreachable or no stored credentials';
      });
    }
  }

  Future<void> _logout() async {
    await _syncService.setEnabled(false);
    await _syncService.setToken('');
    if (mounted) {
      setState(() {
        _syncEnabled = false;
        _hasToken = false;
        _syncStatus = null;
      });
    }
  }

  @override
  void dispose() {
    _serverUrlController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: widget.isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: widget.isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.sync_rounded,
                      color: widget.primaryColor,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Remote Sync',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: widget.isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
                if (_hasToken)
                  Switch(
                    value: _syncEnabled,
                    activeColor: widget.primaryColor,
                    onChanged: (value) async {
                      await _syncService.setEnabled(value);
                      setState(() => _syncEnabled = value);
                      if (value) _doSync();
                    },
                  ),
              ],
            ),

            if (_hasToken) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 16,
                    color: Colors.green.shade400,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Connected to ${_serverUrlController.text}',
                      style: TextStyle(
                        fontSize: 13,
                        color: widget.isDark ? Colors.white54 : Colors.black45,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  OutlinedButton(
                    onPressed: _isSyncing ? null : _doSync,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: widget.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: widget.primaryColor.withOpacity(0.5)),
                    ),
                    child: _isSyncing
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: widget.primaryColor,
                            ),
                          )
                        : const Icon(Icons.sync_rounded, size: 18),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: _isSyncing ? null : _reconnect,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: Colors.orange.withOpacity(0.5)),
                    ),
                    child: const Text('Reconnect'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: _logout,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: Colors.red.withOpacity(0.5)),
                    ),
                    child: const Text('Disconnect'),
                  ),
                ],
              ),
              if (_syncStatus != null) ...[
                const SizedBox(height: 12),
                Text(
                  _syncStatus!,
                  style: TextStyle(
                    fontSize: 13,
                    color: _syncStatus == 'Sync completed'
                        ? Colors.green.shade400
                        : Colors.red.shade400,
                  ),
                ),
              ],
            ] else ...[
              const SizedBox(height: 8),
              Text(
                'Connect to a remote server to sync your data across devices.',
                style: TextStyle(
                  fontSize: 13,
                  color: widget.isDark ? Colors.white38 : Colors.black38,
                ),
              ),
              const SizedBox(height: 20),
              _buildSyncInput(
                controller: _serverUrlController,
                label: 'Server URL',
                hint: 'http://192.168.1.100:8080',
                icon: Icons.dns_outlined,
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 16),
              _buildSyncInput(
                controller: _emailController,
                label: 'Email',
                hint: 'test@localhost',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              _buildSyncInput(
                controller: _passwordController,
                label: 'Password',
                hint: 'Enter password',
                icon: Icons.lock_outlined,
                obscureText: true,
              ),
              if (_loginError != null) ...[
                const SizedBox(height: 12),
                Text(
                  _loginError!,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.red.shade400,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoggingIn ? null : _doLogin,
                  icon: _isLoggingIn
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.login_rounded, size: 20),
                  label: Text(_isLoggingIn ? 'Connecting...' : 'Connect & Sync'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSyncInput({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: widget.isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          style: TextStyle(
            fontSize: 16,
            color: widget.isDark ? Colors.white : Colors.black87,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: widget.isDark ? Colors.white38 : Colors.black38,
            ),
            prefixIcon: Container(
              margin: const EdgeInsets.only(right: 12),
              child: Icon(icon, color: widget.primaryColor, size: 22),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 48),
            filled: true,
            fillColor: widget.isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.grey.withOpacity(0.08),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: widget.primaryColor, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }
}