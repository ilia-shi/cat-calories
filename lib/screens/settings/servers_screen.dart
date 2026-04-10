import 'package:cat_calories/features/sync/syncer.dart';
import 'package:cat_calories_core/features/oauth/domain/auth_credentials.dart';
import 'package:cat_calories_core/features/oauth/domain/auth_credentials_repository.dart';
import 'package:cat_calories_core/features/profile/domain/profile.dart';
import 'package:cat_calories_core/features/profile/domain/profile_repository_interface.dart';
import 'package:cat_calories_core/features/sync/discover_server.dart';
import 'package:cat_calories_core/features/sync/domain/scoped_server_link.dart';
import 'package:cat_calories_core/features/sync/domain/scoped_server_link_repository.dart';
import 'package:cat_calories_core/features/sync/domain/sync_server.dart';
import 'package:cat_calories_core/features/sync/domain/sync_server_repository.dart';
import 'package:cat_calories_core/features/sync/transport/rest/config.dart';
import 'package:cat_calories/screens/auth/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:uuid/uuid.dart';

class EditServersScreen extends StatefulWidget {
  const EditServersScreen({super.key});

  @override
  EditServersScreenState createState() => EditServersScreenState();
}

class EditServersScreenState extends State<EditServersScreen> {
  final _serverRepo = GetIt.instance<SyncServerRepositoryInterface>();
  final _linkRepo = GetIt.instance<ScopedServerLinkRepositoryInterface>();
  final _profileRepo = GetIt.instance<ProfileRepositoryInterface>();
  final _credentialsRepo =
  GetIt.instance<AuthCredentialsRepositoryInterface>();

  List<SyncServer> _servers = [];
  List<Profile> _profiles = [];
  Map<String, List<ScopedServerLink>> _serverLinks = {};
  Map<String, bool> _serverAuth = {};
  final Set<String> _syncingServers = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final servers = await _serverRepo.findAll();
    final profiles = await _profileRepo.fetchAll();
    final links = <String, List<ScopedServerLink>>{};
    final auth = <String, bool>{};

    for (final server in servers) {
      links[server.id] = await _linkRepo.findByServer(server.id);
      final reds = await _credentialsRepo.findByServer(server.id);
      auth[server.id] = reds != null;
    }

    setState(() {
      _servers = servers;
      _profiles = profiles;
      _serverLinks = links;
      _serverAuth = auth;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sync Servers'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _servers.isEmpty
          ? _buildEmptyState(theme, isDark)
          : _buildServerList(theme, isDark),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToEditServer(),
        icon: const Icon(Icons.add),
        label: const Text('Add Server'),
      ),
    );
  }

  Future<void> _navigateToEditServer({SyncServer? server}) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EditServerScreen(server: server),
      ),
    );
    if (saved == true) {
      _loadData();
    }
  }

  Widget _buildEmptyState(ThemeData theme, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 80,
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'No Sync Servers',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add a server to start syncing your data across devices.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => _navigateToEditServer(),
              icon: const Icon(Icons.add),
              label: const Text('Add Server'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServerList(ThemeData theme, bool isDark) {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
        itemCount: _servers.length,
        itemBuilder: (context, index) {
          final server = _servers[index];
          final links = _serverLinks[server.id] ?? [];
          final isAuthenticated = _serverAuth[server.id] ?? false;
          return _buildServerCard(server, links, isAuthenticated, theme, isDark);
        },
      ),
    );
  }

  Widget _buildServerCard(
      SyncServer server,
      List<ScopedServerLink> links,
      bool isAuthenticated,
      ThemeData theme,
      bool isDark,
      ) {
    final linkedProfiles = links
        .map((link) => _profiles.where((p) => p.id == link.scope).firstOrNull)
        .where((p) => p != null)
        .toList();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: isDark ? 0 : 1,
      color: isDark ? Colors.grey[900] : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _navigateToEditServer(server: server),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (_syncingServers.contains(server.id))
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: server.isActive ? Colors.green : Colors.grey,
                      ),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      server.displayName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'sync') {
                        _syncServer(server);
                      } else if (value == 'edit') {
                        _navigateToEditServer(server: server);
                      } else if (value == 'delete') {
                        _confirmDeleteServer(server);
                      } else if (value == 'toggle') {
                        _toggleServerActive(server);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'sync',
                        enabled: isAuthenticated &&
                            !_syncingServers.contains(server.id),
                        child: Row(
                          children: [
                            if (_syncingServers.contains(server.id))
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                CircularProgressIndicator(strokeWidth: 2),
                              )
                            else
                              const Icon(Icons.sync, size: 20),
                            const SizedBox(width: 8),
                            Text(_syncingServers.contains(server.id)
                                ? 'Syncing...'
                                : 'Sync Now'),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 20),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'toggle',
                        child: Row(
                          children: [
                            Icon(
                              server.isActive
                                  ? Icons.pause_circle_outline
                                  : Icons.play_circle_outline,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(server.isActive ? 'Disable' : 'Enable'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline,
                                size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete',
                                style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      server.serverUrls.join(', '),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        if (server.serverVersion != null)
                          _buildBadge('v${server.serverVersion}', theme),
                        _buildBadge(
                            'Protocol ${server.protocolVersion}', theme),
                        if (server.authConfig != null)
                          _buildBadge(
                            server.authConfig!['type']
                                ?.toString()
                                .toUpperCase() ??
                                'AUTH',
                            theme,
                          ),
                        _buildAuthBadge(isAuthenticated, theme),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.person_outline,
                            size: 16,
                            color:
                            isDark ? Colors.grey[400] : Colors.grey[600]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            linkedProfiles.isEmpty
                                ? 'No linked profiles'
                                : linkedProfiles
                                .map((p) => p!.name)
                                .join(', '),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color:
                              isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String text, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }

  Widget _buildAuthBadge(bool isAuthenticated, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isAuthenticated
            ? Colors.green.withValues(alpha: 0.15)
            : Colors.orange.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isAuthenticated ? Icons.lock_open : Icons.lock_outline,
            size: 12,
            color: isAuthenticated ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 4),
          Text(
            isAuthenticated ? 'Logged in' : 'Not logged in',
            style: theme.textTheme.labelSmall?.copyWith(
              color: isAuthenticated ? Colors.green : Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteServer(SyncServer server) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Server?'),
        content: Text(
          'Remove "${server.displayName}"? '
              'This will also remove all profile links for this server.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _credentialsRepo.deleteByServer(server.id);
      final links = _serverLinks[server.id] ?? [];
      for (final link in links) {
        await _linkRepo.delete(link);
      }
      await _serverRepo.delete(server);
      _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Server "${server.displayName}" removed')),
        );
      }
    }
  }

  Future<void> _toggleServerActive(SyncServer server) async {
    final updated = server.copyWith(isActive: !server.isActive);
    await _serverRepo.update(updated);
    _loadData();
  }

  Future<void> _syncServer(SyncServer server) async {
    if (_syncingServers.contains(server.id)) return;
    setState(() => _syncingServers.add(server.id));

    try {
      final syncer = GetIt.instance<Syncer>();
      final result = await syncer.syncServer(server);

      if (mounted) {
        if (result.isFailed) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Sync failed: ${result.error}')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result.message)),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _syncingServers.remove(server.id));
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Add / Edit server screen
// ---------------------------------------------------------------------------

class EditServerScreen extends StatefulWidget {
  final SyncServer? server;

  const EditServerScreen({super.key, this.server});

  @override
  EditServerScreenState createState() => EditServerScreenState();
}

class EditServerScreenState extends State<EditServerScreen> {
  final _serverRepo = GetIt.instance<SyncServerRepositoryInterface>();
  final _linkRepo = GetIt.instance<ScopedServerLinkRepositoryInterface>();
  final _profileRepo = GetIt.instance<ProfileRepositoryInterface>();
  final _credentialsRepo =
  GetIt.instance<AuthCredentialsRepositoryInterface>();

  final _urlControllers = <TextEditingController>[TextEditingController()];
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isConnecting = false;
  SyncConfigResponse? _config;
  String? _error;
  final Set<String> _selectedProfiles = {};
  bool _isSaving = false;
  List<Profile> _profiles = [];
  bool _isLoading = true;

  /// Token obtained from login (for new servers, before save).
  String? _authToken;

  /// Whether existing server has stored credentials.
  bool _hasCredentials = false;

  bool get _isEditing => widget.server != null;
  bool get _isLoggedIn => _authToken != null || _hasCredentials;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final urls = widget.server!.serverUrls;
      _urlControllers.clear();
      for (final url in urls) {
        _urlControllers.add(TextEditingController(text: url));
      }
      if (_urlControllers.isEmpty) {
        _urlControllers.add(TextEditingController());
      }
      _nameController.text = widget.server!.displayName;
    }
    _loadData();
  }

  Future<void> _loadData() async {
    final profiles = await _profileRepo.fetchAll();

    if (_isEditing) {
      final links = await _linkRepo.findByServer(widget.server!.id);
      for (final link in links) {
        _selectedProfiles.add(link.scope);
      }
      final creds = await _credentialsRepo.findByServer(widget.server!.id);
      _hasCredentials = creds != null;
    }

    setState(() {
      _profiles = profiles;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    for (final c in _urlControllers) {
      c.dispose();
    }
    _nameController.dispose();
    super.dispose();
  }

  bool _isValidServerUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return false;

    String host = trimmed;
    if (host.startsWith('http://')) host = host.substring(7);
    if (host.startsWith('https://')) host = host.substring(8);
    if (host.endsWith('/')) host = host.substring(0, host.length - 1);

    final pattern = RegExp(
      r'^([a-zA-Z0-9]([a-zA-Z0-9\-]*[a-zA-Z0-9])?\.)*[a-zA-Z0-9]([a-zA-Z0-9\-]*[a-zA-Z0-9])?(:\d{1,5})?$|'
      r'^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}(:\d{1,5})?$',
    );

    return pattern.hasMatch(host);
  }

  String _primaryUrl() => _urlControllers.first.text.trim();

  String _serverBaseUrl() => normalizeServerUrl(_primaryUrl());

  String _serverDisplayName() {
    final name = _nameController.text.trim();
    if (name.isNotEmpty) return name;
    return _config?.serverName ?? _primaryUrl();
  }

  List<String> _allUrls() =>
      _urlControllers.map((c) => c.text.trim()).where((u) => u.isNotEmpty).toList();

  Future<void> _connect() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isConnecting = true;
      _config = null;
      _error = null;
    });

    try {
      final config = await discoverServer(_primaryUrl());
      // Auto-fill name if empty or still the raw URL
      final currentName = _nameController.text.trim();
      if (currentName.isEmpty ||
          currentName == _primaryUrl()) {
        _nameController.text = config.serverName;
      }
      setState(() {
        _config = config;
        _isConnecting = false;
      });

      // After discovery, navigate to login
      if (mounted) {
        _navigateToLogin();
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isConnecting = false;
      });
    }
  }

  Future<void> _navigateToLogin() async {
    final result = await Navigator.push<LoginResult>(
      context,
      MaterialPageRoute(
        builder: (context) => LoginScreen(
          serverBaseUrl: _serverBaseUrl(),
          serverName: _serverDisplayName(),
        ),
      ),
    );

    if (result != null) {
      setState(() => _authToken = result.token);

      // If editing an existing server, save credentials immediately
      if (_isEditing) {
        await _credentialsRepo.save(AuthCredentials(
          id: const Uuid().v4(),
          serverId: widget.server!.id,
          accessToken: result.token,
          createdAt: DateTime.now(),
        ));
        setState(() => _hasCredentials = true);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logged in successfully')),
        );
      }
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout?'),
        content: const Text('Remove stored credentials for this server?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (_isEditing) {
        await _credentialsRepo.deleteByServer(widget.server!.id);
      }
      setState(() {
        _authToken = null;
        _hasCredentials = false;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final urls = _allUrls();
      final primaryUrl = urls.first;
      final rawName = _nameController.text.trim();
      String baseUrl;
      int protocolVersion;
      String? serverVersion;
      Map<String, dynamic>? authConfig;

      final displayName =
      rawName.isNotEmpty ? rawName : (_config?.serverName ?? primaryUrl);

      if (_config != null) {
        final restConfig =
        _config!.transports['rest'] as Map<String, dynamic>?;
        baseUrl = restConfig?['base_url'] ??
            '${normalizeServerUrl(primaryUrl)}/api/v1';
        protocolVersion = _config!.protocolVersion;
        serverVersion = _config!.serverVersion;
        authConfig = _config!.auth.isNotEmpty ? _config!.auth : null;
      } else if (_isEditing) {
        baseUrl = (widget.server!.transport as RestTransportConfig).baseUrl;
        protocolVersion = widget.server!.protocolVersion;
        serverVersion = widget.server!.serverVersion;
        authConfig = widget.server!.authConfig;
        // If primary URL changed and no new connect, update base URL
        if (primaryUrl != widget.server!.serverUrls.firstOrNull) {
          baseUrl = '${normalizeServerUrl(primaryUrl)}/api/v1';
        }
      } else {
        baseUrl = '${normalizeServerUrl(primaryUrl)}/api/v1';
        protocolVersion = 1;
      }

      if (_isEditing) {
        final updated = widget.server!.copyWith(
          displayName: displayName,
          transport: RestTransportConfig(baseUrl: baseUrl),
          protocolVersion: protocolVersion,
          serverUrls: urls,
          serverVersion: serverVersion,
          authConfig: authConfig,
        );
        await _serverRepo.update(updated);
        await _syncProfileLinks(updated.id);
      } else {
        final server = SyncServer(
          id: const Uuid().v4(),
          displayName: displayName,
          transport: RestTransportConfig(baseUrl: baseUrl),
          isActive: true,
          createdAt: DateTime.now(),
          protocolVersion: protocolVersion,
          serverUrls: urls,
          serverVersion: serverVersion,
          authConfig: authConfig,
        );
        await _serverRepo.insert(server);
        await _syncProfileLinks(server.id);

        // Save credentials for the new server
        if (_authToken != null) {
          await _credentialsRepo.save(AuthCredentials(
            id: const Uuid().v4(),
            serverId: server.id,
            accessToken: _authToken!,
            createdAt: DateTime.now(),
          ));
        }
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    }
  }

  Future<void> _syncProfileLinks(String serverId) async {
    final existingLinks = await _linkRepo.findByServer(serverId);
    final existingScopes = existingLinks.map((l) => l.scope).toSet();

    // Remove deselected
    for (final link in existingLinks) {
      if (!_selectedProfiles.contains(link.scope)) {
        await _linkRepo.delete(link);
      }
    }

    // Add newly selected
    for (final scope in _selectedProfiles) {
      if (!existingScopes.contains(scope)) {
        await _linkRepo.insert(ScopedServerLink(
          id: const Uuid().v4(),
          scope: scope,
          serverId: serverId,
          linkedAt: DateTime.now(),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Server' : 'Add Sync Server'),
        actions: [
          TextButton.icon(
            onPressed: _isSaving ? null : _save,
            icon: _isSaving
                ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : const Icon(Icons.check),
            label: Text(_isSaving ? 'Saving...' : 'Save'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Form(
            key: _formKey,
            child: Column(
              children: [
                ...List.generate(_urlControllers.length, (i) {
                  final isFirst = i == 0;
                  return Padding(
                    padding: EdgeInsets.only(bottom: i < _urlControllers.length - 1 ? 8 : 0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _urlControllers[i],
                            decoration: InputDecoration(
                              labelText: isFirst
                                  ? 'Server Address'
                                  : 'Alternative Address ${i + 1}',
                              hintText: '192.168.1.50:8080',
                              helperText: isFirst
                                  ? 'Primary address. Alternatives are tried if this fails.'
                                  : null,
                              prefixIcon: const Icon(Icons.link),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor:
                              isDark ? Colors.grey[800] : Colors.grey[50],
                            ),
                            keyboardType: TextInputType.url,
                            textInputAction: TextInputAction.next,
                            enabled: _config == null && !_isSaving,
                            onFieldSubmitted: isFirst ? (_) => _connect() : null,
                            validator: isFirst
                                ? (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter a server address';
                              }
                              if (!_isValidServerUrl(value)) {
                                return 'Enter a valid address (e.g., 192.168.1.50:8080)';
                              }
                              return null;
                            }
                                : (value) {
                              if (value != null &&
                                  value.trim().isNotEmpty &&
                                  !_isValidServerUrl(value)) {
                                return 'Enter a valid address';
                              }
                              return null;
                            },
                          ),
                        ),
                        if (!isFirst)
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline,
                                color: Colors.red),
                            onPressed: _isSaving
                                ? null
                                : () {
                              setState(() {
                                _urlControllers[i].dispose();
                                _urlControllers.removeAt(i);
                              });
                            },
                          ),
                      ],
                    ),
                  );
                }),
                if (_config == null && !_isSaving)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _urlControllers.add(TextEditingController());
                        });
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add alternative address'),
                    ),
                  ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Display Name',
                    hintText: 'My home server',
                    helperText: 'Optional. Auto-filled on connect.',
                    prefixIcon: const Icon(Icons.label_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor:
                    isDark ? Colors.grey[800] : Colors.grey[50],
                  ),
                  textInputAction: TextInputAction.done,
                  textCapitalization: TextCapitalization.sentences,
                  enabled: !_isSaving,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_config == null && !_isConnecting && _error == null)
            FilledButton.icon(
              onPressed: _connect,
              icon: const Icon(Icons.wifi_tethering),
              label: Text(_isEditing ? 'Reconnect' : 'Connect'),
            ),
          if (_isConnecting)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Card(
              color: Colors.red.withValues(alpha: 0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                    color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(
                            color:
                            isDark ? Colors.red[300] : Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                setState(() => _error = null);
              },
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Try Again'),
            ),
          ],
          if (_config != null) ...[
            const SizedBox(height: 8),
            _buildConnectionCard(theme, isDark),
          ],
          if (_isEditing && _config == null) ...[
            const SizedBox(height: 8),
            _buildCurrentServerInfo(theme, isDark),
          ],
          // Auth section
          const SizedBox(height: 24),
          _buildAuthSection(theme, isDark),
          const SizedBox(height: 24),
          Text(
            'Link Profiles',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          if (_profiles.isEmpty)
            Text(
              'No profiles available.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            )
          else
            ..._profiles.map((profile) {
              return CheckboxListTile(
                title: Text(profile.name),
                value: _selectedProfiles.contains(profile.id),
                onChanged: (checked) {
                  setState(() {
                    if (checked == true) {
                      _selectedProfiles.add(profile.id!);
                    } else {
                      _selectedProfiles.remove(profile.id);
                    }
                  });
                },
                contentPadding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildConnectionCard(ThemeData theme, bool isDark) {
    return Card(
      color: Colors.green.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.green.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle,
                    color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Connected!',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _config!.serverName,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Version ${_config!.serverVersion}'
                  ' \u2022 Protocol v${_config!.protocolVersion}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            if (_config!.auth.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Auth: ${_config!.auth['type'] ?? 'unknown'}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAuthSection(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Authentication',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          color: isDark ? Colors.grey[900] : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  _isLoggedIn ? Icons.lock_open : Icons.lock_outline,
                  color: _isLoggedIn ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isLoggedIn ? 'Logged in' : 'Not logged in',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: _isLoggedIn ? Colors.green : Colors.orange,
                        ),
                      ),
                      Text(
                        _isLoggedIn
                            ? 'Server requests are authenticated'
                            : 'Login to sync data with this server',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isLoggedIn)
                  TextButton(
                    onPressed: _logout,
                    child: const Text('Logout'),
                  )
                else if (_isValidServerUrl(_primaryUrl()))
                  FilledButton.tonal(
                    onPressed: _navigateToLogin,
                    child: const Text('Login'),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentServerInfo(ThemeData theme, bool isDark) {
    final server = widget.server!;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              server.displayName,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (server.serverVersion != null) ...[
              const SizedBox(height: 4),
              Text(
                'Version ${server.serverVersion}'
                    ' \u2022 Protocol v${server.protocolVersion}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ],
            if (server.authConfig != null) ...[
              const SizedBox(height: 4),
              Text(
                'Auth: ${server.authConfig!['type'] ?? 'unknown'}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
