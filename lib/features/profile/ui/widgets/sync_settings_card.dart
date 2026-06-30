import 'package:cat_calories/common/locator.dart';
import 'package:cat_calories/features/sync/sync_service.dart';
import 'package:flutter/material.dart';

import 'profile_input_field.dart';
import 'profile_settings_card.dart';

/// Remote-sync settings: log in to a server, then sync / reconnect / disconnect.
/// Owns the auth + sync orchestration; rendering of each state is delegated to
/// [_SyncConnectedView] and [_SyncLoginForm].
class SyncSettingsCard extends StatefulWidget {
  final bool isDark;
  final Color primaryColor;

  const SyncSettingsCard({
    super.key,
    required this.isDark,
    required this.primaryColor,
  });

  @override
  State<SyncSettingsCard> createState() => _SyncSettingsCardState();
}

class _SyncSettingsCardState extends State<SyncSettingsCard> {
  final _syncService = locator.get<SyncService>();
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

    if (!mounted) {
      return;
    }

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

    if (!mounted) {
      return;
    }

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

    if (!mounted) {
      return;
    }

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
        _syncStatus =
            'Reconnect failed: server unreachable or no stored credentials';
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
    return ProfileSettingsCard(
      isDark: widget.isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.sync_rounded, color: widget.primaryColor, size: 22),
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
                    if (value) {
                      _doSync();
                    }
                  },
                ),
            ],
          ),
          if (_hasToken)
            _SyncConnectedView(
              isDark: widget.isDark,
              primaryColor: widget.primaryColor,
              serverUrl: _serverUrlController.text,
              isSyncing: _isSyncing,
              syncStatus: _syncStatus,
              onSync: _doSync,
              onReconnect: _reconnect,
              onLogout: _logout,
            )
          else
            _SyncLoginForm(
              isDark: widget.isDark,
              primaryColor: widget.primaryColor,
              serverUrlController: _serverUrlController,
              emailController: _emailController,
              passwordController: _passwordController,
              loginError: _loginError,
              isLoggingIn: _isLoggingIn,
              onConnect: _doLogin,
            ),
        ],
      ),
    );
  }
}

/// Shown once authenticated: connection status, sync/reconnect/disconnect
/// actions, and the last sync result.
class _SyncConnectedView extends StatelessWidget {
  final bool isDark;
  final Color primaryColor;
  final String serverUrl;
  final bool isSyncing;
  final String? syncStatus;
  final VoidCallback onSync;
  final VoidCallback onReconnect;
  final VoidCallback onLogout;

  const _SyncConnectedView({
    required this.isDark,
    required this.primaryColor,
    required this.serverUrl,
    required this.isSyncing,
    required this.syncStatus,
    required this.onSync,
    required this.onReconnect,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(Icons.check_circle_outline, size: 16, color: Colors.green.shade400),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Connected to $serverUrl',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            OutlinedButton(
              onPressed: isSyncing ? null : onSync,
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: BorderSide(color: primaryColor.withOpacity(0.5)),
              ),
              child: isSyncing
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: primaryColor,
                      ),
                    )
                  : const Icon(Icons.sync_rounded, size: 18),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: isSyncing ? null : onReconnect,
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
              onPressed: onLogout,
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
        if (syncStatus != null) ...[
          const SizedBox(height: 12),
          Text(
            syncStatus!,
            style: TextStyle(
              fontSize: 13,
              color: syncStatus == 'Sync completed'
                  ? Colors.green.shade400
                  : Colors.red.shade400,
            ),
          ),
        ],
      ],
    );
  }
}

/// Shown when not authenticated: server URL / email / password fields and the
/// "Connect & Sync" button.
class _SyncLoginForm extends StatelessWidget {
  final bool isDark;
  final Color primaryColor;
  final TextEditingController serverUrlController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final String? loginError;
  final bool isLoggingIn;
  final VoidCallback onConnect;

  const _SyncLoginForm({
    required this.isDark,
    required this.primaryColor,
    required this.serverUrlController,
    required this.emailController,
    required this.passwordController,
    required this.loginError,
    required this.isLoggingIn,
    required this.onConnect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          'Connect to a remote server to sync your data across devices.',
          style: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.white38 : Colors.black38,
          ),
        ),
        const SizedBox(height: 20),
        ProfileInputField(
          controller: serverUrlController,
          label: 'Server URL',
          hint: 'http://192.168.1.100:8080',
          icon: Icons.dns_outlined,
          isDark: isDark,
          primaryColor: primaryColor,
          keyboardType: TextInputType.url,
        ),
        const SizedBox(height: 16),
        ProfileInputField(
          controller: emailController,
          label: 'Email',
          hint: 'test@localhost',
          icon: Icons.email_outlined,
          isDark: isDark,
          primaryColor: primaryColor,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        ProfileInputField(
          controller: passwordController,
          label: 'Password',
          hint: 'Enter password',
          icon: Icons.lock_outlined,
          isDark: isDark,
          primaryColor: primaryColor,
          obscureText: true,
        ),
        if (loginError != null) ...[
          const SizedBox(height: 12),
          Text(
            loginError!,
            style: TextStyle(fontSize: 13, color: Colors.red.shade400),
          ),
        ],
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: isLoggingIn ? null : onConnect,
            icon: isLoggingIn
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.login_rounded, size: 20),
            label: Text(isLoggingIn ? 'Connecting...' : 'Connect & Sync'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
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
    );
  }
}
