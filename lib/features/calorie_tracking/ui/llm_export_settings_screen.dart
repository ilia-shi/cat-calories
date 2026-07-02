import 'package:cat_calories/common/locator.dart';
import 'package:cat_calories/common/theme/colors.dart';
import 'package:cat_calories/common/widgets/app_card.dart';
import 'package:cat_calories/common/widgets/error_display.dart';
import 'package:cat_calories/features/calorie_tracking/llm_export_service.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/llm_export_formatter.dart';
import 'package:flutter/material.dart';

/// Settings for the LLM markdown export: export directory (e.g. a
/// Syncthing-synced folder), auto-export on background, editable preamble.
class LlmExportSettingsScreen extends StatefulWidget {
  const LlmExportSettingsScreen({super.key});

  @override
  State<LlmExportSettingsScreen> createState() =>
      _LlmExportSettingsScreenState();
}

class _LlmExportSettingsScreenState extends State<LlmExportSettingsScreen> {
  final _service = locator.get<LlmExportService>();
  final _directoryController = TextEditingController();
  final _preambleController = TextEditingController();
  bool _autoExport = false;
  String? _directoryStatus;
  bool _directoryOk = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _directoryController.dispose();
    _preambleController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final directory = await _service.getDirectory();
    final preamble = await _service.getPreamble();
    final autoExport = await _service.isAutoExportEnabled();
    if (mounted) {
      setState(() {
        _directoryController.text = directory ?? '';
        _preambleController.text = preamble ?? '';
        _autoExport = autoExport;
      });
    }
  }

  Future<void> _testDirectory() async {
    final path = _directoryController.text.trim();
    if (path.isEmpty) {
      setState(() {
        _directoryStatus = 'Enter a directory path first';
        _directoryOk = false;
      });
      return;
    }
    final error = await _service.testDirectory(path);
    if (mounted) {
      setState(() {
        _directoryStatus = error ?? 'Writable — exports will land here';
        _directoryOk = error == null;
      });
    }
  }

  Future<void> _save() async {
    await _service.setDirectory(_directoryController.text);
    await _service.setPreamble(_preambleController.text);
    await _service.setAutoExportEnabled(_autoExport);
    if (mounted) {
      ErrorDisplay.showSuccess(context, 'LLM export settings saved');
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LLM Export'),
        actions: [
          TextButton(onPressed: _save, child: const Text('Save')),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _DirectoryCard(
            controller: _directoryController,
            status: _directoryStatus,
            statusOk: _directoryOk,
            onTest: _testDirectory,
          ),
          const SizedBox(height: 16),
          _AutoExportCard(
            enabled: _autoExport,
            onChanged: (value) => setState(() => _autoExport = value),
          ),
          const SizedBox(height: 16),
          _PreambleCard(controller: _preambleController),
        ],
      ),
    );
  }
}

class _DirectoryCard extends StatelessWidget {
  final TextEditingController controller;
  final String? status;
  final bool statusOk;
  final VoidCallback onTest;

  const _DirectoryCard({
    required this.controller,
    required this.status,
    required this.statusOk,
    required this.onTest,
  });

  @override
  Widget build(BuildContext context) {
    final appColors = AppColors.of(context);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardTitle(
            icon: Icons.folder_outlined,
            title: 'Export directory',
          ),
          const SizedBox(height: 8),
          Text(
            'Folder the markdown log is written into — point it at a '
            'Syncthing-synced folder to read the log on other devices. '
            'Leave empty to export via the share sheet only.',
            style: TextStyle(fontSize: 12, color: appColors.textTertiary),
          ),
          const SizedBox(height: 12),
          _SquircleField(
            controller: controller,
            hint: '/storage/emulated/0/Sync/cat-calories',
            maxLines: 1,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              OutlinedButton(
                onPressed: onTest,
                style: OutlinedButton.styleFrom(
                  shape: AppCard.squircleBorder(radius: 10),
                ),
                child: const Text('Test write'),
              ),
              const SizedBox(width: 12),
              if (status != null)
                Expanded(
                  child: Text(
                    status!,
                    style: TextStyle(
                      fontSize: 12,
                      color: statusOk ? SuccessColor : DangerColor,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AutoExportCard extends StatelessWidget {
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _AutoExportCard({required this.enabled, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final appColors = AppColors.of(context);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: _CardTitle(
                  icon: Icons.autorenew_rounded,
                  title: 'Auto-export',
                ),
              ),
              Switch(value: enabled, onChanged: onChanged),
            ],
          ),
          Text(
            'Rewrite the log in the export directory every time the app goes '
            'to the background. Does nothing while no directory is set.',
            style: TextStyle(fontSize: 12, color: appColors.textTertiary),
          ),
        ],
      ),
    );
  }
}

class _PreambleCard extends StatelessWidget {
  final TextEditingController controller;

  const _PreambleCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    final appColors = AppColors.of(context);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardTitle(
            icon: Icons.notes_rounded,
            title: 'Preamble for the LLM',
          ),
          const SizedBox(height: 8),
          Text(
            'Opens the exported log: your goals and the questions you want '
            'answered. Leave empty to use the default below.',
            style: TextStyle(fontSize: 12, color: appColors.textTertiary),
          ),
          const SizedBox(height: 12),
          _SquircleField(
            controller: controller,
            hint: LlmExportFormatter.defaultPreamble,
            maxLines: 8,
            minLines: 4,
          ),
        ],
      ),
    );
  }
}

class _CardTitle extends StatelessWidget {
  final IconData icon;
  final String title;

  const _CardTitle({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    final appColors = AppColors.of(context);

    return Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).primaryColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: appColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _SquircleField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final int? minLines;

  const _SquircleField({
    required this.controller,
    required this.hint,
    required this.maxLines,
    this.minLines,
  });

  @override
  Widget build(BuildContext context) {
    final appColors = AppColors.of(context);

    return DecoratedBox(
      decoration: ShapeDecoration(
        color: appColors.surfaceMuted,
        shape: AppCard.squircleBorder(radius: 12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: TextField(
          controller: controller,
          maxLines: maxLines,
          minLines: minLines,
          style: TextStyle(fontSize: 13, color: appColors.textPrimary),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.transparent,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            hintText: hint,
            hintStyle: TextStyle(
              fontSize: 12,
              color: appColors.textDisabled,
            ),
            hintMaxLines: 6,
          ),
        ),
      ),
    );
  }
}
