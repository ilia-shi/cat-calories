import 'package:cat_calories/common/locator.dart';
import 'package:cat_calories/features/embedded_server/embedded_server_service.dart';
import 'package:cat_calories/features/embedded_server/screen_energy_service.dart';
import 'package:flutter/material.dart';

import 'profile_settings_card.dart';

/// Screen-energy settings for the embedded web server: how long until the
/// screen turns off, and when it dims, while the server is running.
class WebServerSettingsCard extends StatefulWidget {
  final bool isDark;
  final Color primaryColor;

  const WebServerSettingsCard({
    super.key,
    required this.isDark,
    required this.primaryColor,
  });

  @override
  State<WebServerSettingsCard> createState() => _WebServerSettingsCardState();
}

class _WebServerSettingsCardState extends State<WebServerSettingsCard> {
  final _screenEnergy = locator.get<EmbeddedServerService>().screenEnergy;
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
    if (minutes == 0) {
      return 'Never';
    }
    if (minutes == 1) {
      return '1 minute';
    }
    return '$minutes minutes';
  }

  String _formatDimTimeout(int minutes) {
    if (minutes == -1) {
      return 'Default';
    }
    if (minutes == 0) {
      return 'Never';
    }
    if (minutes == 1) {
      return '1 minute';
    }
    return '$minutes minutes';
  }

  @override
  Widget build(BuildContext context) {
    return ProfileSettingsCard(
      isDark: widget.isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LabeledDropdown(
            isDark: widget.isDark,
            primaryColor: widget.primaryColor,
            label: 'Screen timeout',
            value: _selectedMinutes,
            options: ScreenEnergyService.timeoutOptions,
            format: _formatTimeout,
            iconFor: (minutes) =>
                minutes == 0 ? Icons.visibility : Icons.timer_outlined,
            info:
                'Turn off screen after inactivity while the web server is running',
            onChanged: (value) {
              setState(() => _selectedMinutes = value);
              _screenEnergy.setTimeoutMinutes(value);
            },
          ),
          const SizedBox(height: 24),
          _LabeledDropdown(
            isDark: widget.isDark,
            primaryColor: widget.primaryColor,
            label: 'Dim brightness',
            value: _selectedDimMinutes,
            options: ScreenEnergyService.dimTimeoutOptions,
            format: _formatDimTimeout,
            iconFor: (minutes) =>
                minutes == 0 ? Icons.brightness_high : Icons.brightness_low,
            info:
                'Reduce screen brightness before turning off. Default uses device screen timeout.',
            onChanged: (value) {
              setState(() => _selectedDimMinutes = value);
              _screenEnergy.setDimTimeoutMinutes(value);
            },
          ),
        ],
      ),
    );
  }
}

/// A labelled dropdown of timeout options with an info line below it.
class _LabeledDropdown extends StatelessWidget {
  final bool isDark;
  final Color primaryColor;
  final String label;
  final int value;
  final List<int> options;
  final String Function(int) format;
  final IconData Function(int) iconFor;
  final ValueChanged<int> onChanged;
  final String info;

  const _LabeledDropdown({
    required this.isDark,
    required this.primaryColor,
    required this.label,
    required this.value,
    required this.options,
    required this.format,
    required this.iconFor,
    required this.onChanged,
    required this.info,
  });

  @override
  Widget build(BuildContext context) {
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
        Container(
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.grey.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: value,
              isExpanded: true,
              icon: Icon(
                Icons.arrow_drop_down_rounded,
                color: isDark ? Colors.white54 : Colors.black45,
              ),
              dropdownColor: isDark ? const Color(0xFF2A2A2A) : Colors.white,
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.white : Colors.black87,
              ),
              items: options.map((minutes) {
                return DropdownMenuItem<int>(
                  value: minutes,
                  child: Row(
                    children: [
                      Icon(iconFor(minutes), size: 18, color: primaryColor),
                      const SizedBox(width: 12),
                      Text(format(minutes)),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (v) {
                if (v == null) {
                  return;
                }
                onChanged(v);
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
              color: isDark ? Colors.white38 : Colors.black38,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                info,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
