import 'package:flutter/material.dart';
import '../models/role.dart';
import '../models/user.dart';
import '../services/analysis_service.dart';
import '../services/auth_service.dart';
import '../services/backend_paper_service.dart';
import 'profile_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final tabs = [
      const _AdminDashboardTab(),
      const _AdminUsersTab(),
      const _SyncLogsTab(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Users',
          ),
          NavigationDestination(
            icon: Icon(Icons.sync_outlined),
            selectedIcon: Icon(Icons.sync),
            label: 'Sync',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// ── Dashboard Tab ─────────────────────────────────────────────────────────────

class _AdminDashboardTab extends StatefulWidget {
  const _AdminDashboardTab();

  @override
  State<_AdminDashboardTab> createState() => _AdminDashboardTabState();
}

class _AdminDashboardTabState extends State<_AdminDashboardTab> {
  final _service = AnalysisService();
  final _paperService = BackendPaperService();
  Map<String, dynamic>? _stats;
  bool _loading = true;
  String? _error;
  bool _syncingWorks = false;
  bool _recomputingTrends = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _service.getAdminDashboard();
      setState(() {
        _stats = data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _syncWorks() async {
    setState(() => _syncingWorks = true);
    try {
      final msg = await _paperService.triggerSync();
      _showSnack(msg);
    } catch (e) {
      _showSnack('Sync failed: $e');
    } finally {
      if (mounted) setState(() => _syncingWorks = false);
    }
  }

  Future<void> _recomputeTrends() async {
    setState(() => _recomputingTrends = true);
    try {
      final msg = await _paperService.triggerRecomputeTrends();
      _showSnack(msg);
    } catch (e) {
      _showSnack('Recompute failed: $e');
    } finally {
      if (mounted) setState(() => _recomputingTrends = false);
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, style: TextStyle(color: colorScheme.error)),
                      const SizedBox(height: 12),
                      FilledButton(onPressed: _load, child: const Text('Retry')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Stats grid
                      Text('System Overview',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.8,
                        children: [
                          _StatCard(
                            label: 'Users',
                            value: '${_stats?['userCount'] ?? 0}',
                            icon: Icons.people,
                            color: colorScheme.primary,
                            sub: '${_stats?['bannedCount'] ?? 0} banned',
                          ),
                          _StatCard(
                            label: 'Papers',
                            value: '${_stats?['paperCount'] ?? 0}',
                            icon: Icons.article_outlined,
                            color: Colors.green.shade600,
                          ),
                          _StatCard(
                            label: 'Topics',
                            value: '${_stats?['topicCount'] ?? 0}',
                            icon: Icons.category_outlined,
                            color: Colors.orange.shade600,
                          ),
                          _StatCard(
                            label: 'Journals',
                            value: '${_stats?['journalCount'] ?? 0}',
                            icon: Icons.menu_book_outlined,
                            color: Colors.purple.shade600,
                          ),
                          _StatCard(
                            label: 'Authors',
                            value: '${_stats?['authorCount'] ?? 0}',
                            icon: Icons.person_outline,
                            color: Colors.teal.shade600,
                          ),
                          _StatCard(
                            label: 'Sync Logs',
                            value: '${_stats?['syncLogCount'] ?? 0}',
                            icon: Icons.sync_outlined,
                            color: Colors.blue.shade600,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Sync actions
                      Text('Sync Controls',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Card(
                        child: Column(
                          children: [
                            ListTile(
                              leading: const Icon(Icons.cloud_sync_outlined),
                              title: const Text('Sync papers from OpenAlex'),
                              subtitle: const Text(
                                  'Pulls new works, notifies users via FCM'),
                              trailing: _syncingWorks
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2))
                                  : FilledButton(
                                      onPressed: _syncWorks,
                                      child: const Text('Run')),
                            ),
                            const Divider(height: 1),
                            ListTile(
                              leading: const Icon(Icons.auto_graph_outlined),
                              title: const Text('Recompute publication trends'),
                              trailing: _recomputingTrends
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2))
                                  : FilledButton(
                                      onPressed: _recomputeTrends,
                                      child: const Text('Run')),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Recent sync logs
                      if (_stats?['recentSyncLogs'] != null) ...[
                        Text('Recent Sync Logs',
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        ...(_stats!['recentSyncLogs'] as List).map((log) =>
                            _SyncLogTile(log: log as Map<String, dynamic>)),
                      ],
                    ],
                  ),
                ),
    );
  }
}

// ── Users Tab ──────────────────────────────────────────────────────────────────

class _AdminUsersTab extends StatefulWidget {
  const _AdminUsersTab();

  @override
  State<_AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends State<_AdminUsersTab> {
  final _authService = AuthService();
  final _analysisService = AnalysisService();
  List<User> _users = [];
  List<Role> _roles = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _analysisService.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _authService.getAllUsers(),
        _authService.getAvailableRoles(),
      ]);
      if (!mounted) return;
      setState(() {
        _users = results[0] as List<User>;
        _roles = results[1] as List<Role>;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _changeRole(User user, String roleId) async {
    try {
      await _authService.assignRole(user.userId, roleId);
      _showSnack('Updated ${user.fullName}\'s role');
      await _load();
    } catch (e) {
      _showSnack('Failed to update role: $e');
    }
  }

  Future<void> _toggleBan(User user) async {
    final isBanned = user.isBanned == true;
    try {
      if (isBanned) {
        await _analysisService.unbanUser(user.userId);
        _showSnack('${user.fullName} unbanned');
      } else {
        await _analysisService.banUser(user.userId);
        _showSnack('${user.fullName} banned');
      }
      await _load();
    } catch (e) {
      _showSnack('Failed: $e');
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Text(_error!,
                      style: TextStyle(color: colorScheme.error)))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _users.length,
                    itemBuilder: (context, i) {
                      final u = _users[i];
                      final banned = u.isBanned == true;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: banned
                                ? colorScheme.errorContainer
                                : colorScheme.primaryContainer,
                            child: Text(
                              u.fullName.isNotEmpty
                                  ? u.fullName[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                color: banned
                                    ? colorScheme.onErrorContainer
                                    : colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                  child: Text(u.fullName,
                                      overflow: TextOverflow.ellipsis)),
                              if (banned)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    color: colorScheme.errorContainer,
                                  ),
                                  child: Text(
                                    'Banned',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: colorScheme.onErrorContainer,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(u.email,
                                  style: const TextStyle(fontSize: 12),
                                  overflow: TextOverflow.ellipsis),
                              DropdownButton<String>(
                                value: _roles.any((r) => r.roleId == u.roleId)
                                    ? u.roleId
                                    : null,
                                hint: Text(u.roleName),
                                isDense: true,
                                items: _roles
                                    .map((r) => DropdownMenuItem(
                                          value: r.roleId,
                                          child:
                                              Text(r.roleName ?? r.roleId),
                                        ))
                                    .toList(),
                                onChanged: (roleId) {
                                  if (roleId != null && roleId != u.roleId) {
                                    _changeRole(u, roleId);
                                  }
                                },
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            tooltip: banned ? 'Unban user' : 'Ban user',
                            icon: Icon(
                              banned ? Icons.lock_open : Icons.block,
                              color: banned
                                  ? Colors.green
                                  : colorScheme.error,
                            ),
                            onPressed: () => _toggleBan(u),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

// ── Sync Logs Tab ──────────────────────────────────────────────────────────────

class _SyncLogsTab extends StatefulWidget {
  const _SyncLogsTab();

  @override
  State<_SyncLogsTab> createState() => _SyncLogsTabState();
}

class _SyncLogsTabState extends State<_SyncLogsTab> {
  final _service = AnalysisService();
  List<dynamic> _logs = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final logs = await _service.getSyncLogs(take: 100);
      setState(() {
        _logs = logs;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sync Logs'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Text(_error!,
                      style: TextStyle(color: colorScheme.error)))
              : _logs.isEmpty
                  ? const Center(child: Text('No sync logs yet.'))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _logs.length,
                        itemBuilder: (context, i) {
                          final log = _logs[i] as Map<String, dynamic>;
                          return _SyncLogTile(log: log);
                        },
                      ),
                    ),
    );
  }
}

// ── Shared widgets ─────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.sub,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? sub;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: colorScheme.surface,
        border: Border.all(color: colorScheme.outline.withAlpha(20)),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withAlpha(25),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                      fontSize: 12, color: colorScheme.onSurface.withAlpha(150)),
                ),
                if (sub != null)
                  Text(
                    sub!,
                    style: TextStyle(fontSize: 10, color: color),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SyncLogTile extends StatelessWidget {
  const _SyncLogTile({required this.log});
  final Map<String, dynamic> log;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final status = log['status']?.toString() ?? 'unknown';
    final isSuccess = status.toLowerCase() == 'success';
    final isError = status.toLowerCase().contains('error') ||
        status.toLowerCase().contains('fail');

    final statusColor = isSuccess
        ? Colors.green.shade600
        : isError
            ? colorScheme.error
            : Colors.orange.shade600;

    final rawTime = log['syncTime']?.toString();
    String timeDisplay = 'N/A';
    if (rawTime != null) {
      final dt = DateTime.tryParse(rawTime);
      if (dt != null) {
        timeDisplay =
            '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
            '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withAlpha(25),
          child: Icon(
            isSuccess
                ? Icons.check_circle_outline
                : isError
                    ? Icons.error_outline
                    : Icons.hourglass_empty,
            color: statusColor,
            size: 18,
          ),
        ),
        title: Text(
          log['sourceApi']?.toString() ?? 'Unknown source',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$timeDisplay • ${log['recordsInserted'] ?? 0} records inserted',
              style: TextStyle(
                  fontSize: 11, color: colorScheme.onSurface.withAlpha(140)),
            ),
            if (log['errorMessage'] != null &&
                log['errorMessage'].toString().isNotEmpty)
              Text(
                log['errorMessage'].toString(),
                style: TextStyle(fontSize: 11, color: colorScheme.error),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: statusColor.withAlpha(20),
          ),
          child: Text(
            status,
            style: TextStyle(
                fontSize: 11,
                color: statusColor,
                fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}
