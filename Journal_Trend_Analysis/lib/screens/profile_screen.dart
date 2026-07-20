import 'dart:async';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/theme_provider.dart';
import '../services/analytics_service_flutter.dart';
import '../widgets/modern_app_bar.dart';
import 'notifications_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = context.watch<ThemeProvider>();
    final profile = context.watch<ProfileProvider>();
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: const ModernAppBar(title: 'Settings'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        children: [
          _Header(
            isDark: isDark,
            daysActive: profile.daysActive,
            searchesRun: profile.searchesRun,
            auth: auth,
          ),
          const SizedBox(height: 18),

          _SectionTitle(title: 'Preferences'),
          const SizedBox(height: 10),
          _Card(
            child: SwitchListTile.adaptive(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 4,
              ),
              secondary: Icon(
                theme.isDark
                    ? Icons.dark_mode_rounded
                    : Icons.light_mode_rounded,
                color: colorScheme.primary,
              ),
              title: const Text(
                'Dark mode',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                theme.isDark ? 'On' : 'Off',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurface.withAlpha(150),
                ),
              ),
              value: theme.isDark,
              onChanged: (_) => theme.toggle(),
            ),
          ),

          if (auth.isAuthenticated && auth.user != null) ...[
            const SizedBox(height: 18),
            _SectionTitle(title: 'Notifications & FCM'),
            const SizedBox(height: 10),
            _NotificationMessagingSection(userId: auth.user!.userId),
          ],

          if (kDebugMode) ...[
            const SizedBox(height: 18),
            _SectionTitle(title: 'Developer'),
            const SizedBox(height: 10),
            _Card(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 4,
                ),
                leading: Icon(
                  Icons.bug_report_rounded,
                  color: colorScheme.error,
                ),
                title: const Text(
                  'Trigger Crashlytics test crash',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                subtitle: const Text('Debug builds only'),
                onTap: () {
                  FirebaseCrashlytics.instance.log('Debug test crash button');
                  throw Exception('RuntimeException("Test Crash")');
                },
              ),
            ),
          ],

          const SizedBox(height: 18),
          _SectionTitle(title: 'Activity'),
          const SizedBox(height: 10),
          _Card(
            child: Column(
              children: [
                _StatRow(
                  icon: Icons.calendar_today_rounded,
                  label: 'Days active',
                  value: '${profile.daysActive}',
                ),
                Divider(height: 1, color: colorScheme.outline.withAlpha(20)),
                _StatRow(
                  icon: Icons.travel_explore_rounded,
                  label: 'Searches run',
                  value: '${profile.searchesRun}',
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),
          _SectionTitle(title: 'Account'),
          const SizedBox(height: 10),
          _Card(
            child: Column(
              children: [
                if (auth.isAuthenticated && auth.user != null) ...[
                  _StatRow(
                    icon: Icons.email_rounded,
                    label: 'Email',
                    value: auth.user!.email.isNotEmpty
                        ? auth.user!.email
                        : 'Not set',
                  ),
                  Divider(height: 1, color: colorScheme.outline.withAlpha(20)),
                  _StatRow(
                    icon: Icons.badge_rounded,
                    label: 'Role',
                    value: _formatRole(auth.user!.roleId, auth.user!.roleName),
                  ),
                  Divider(height: 1, color: colorScheme.outline.withAlpha(20)),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 4,
                    ),
                    leading: Icon(
                      Icons.logout_rounded,
                      color: colorScheme.error,
                    ),
                    title: const Text(
                      'Sign out',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    trailing: Icon(
                      Icons.chevron_right_rounded,
                      color: colorScheme.onSurface.withAlpha(150),
                    ),
                    onTap: () async {
                      await _confirmLogout(context, auth);
                    },
                  ),
                ] else
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 4,
                    ),
                    leading: Icon(
                      Icons.login_rounded,
                      color: colorScheme.primary,
                    ),
                    title: const Text(
                      'Sign in',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    trailing: Icon(
                      Icons.chevron_right_rounded,
                      color: colorScheme.onSurface.withAlpha(150),
                    ),
                    onTap: () {
                      Navigator.of(context).pushNamed('/login');
                    },
                  ),
              ],
            ),
          ),

          const SizedBox(height: 18),
          _SectionTitle(title: 'About'),
          const SizedBox(height: 10),
          _Card(
            child: Column(
              children: [
                _StatRow(
                  icon: Icons.info_outline_rounded,
                  label: 'App',
                  value: 'ResearchHub',
                ),
                Divider(height: 1, color: colorScheme.outline.withAlpha(20)),
                _StatRow(
                  icon: Icons.cloud_outlined,
                  label: 'Data source',
                  value: 'OpenAlex',
                ),
                Divider(height: 1, color: colorScheme.outline.withAlpha(20)),
                _StatRow(
                  icon: Icons.tag_rounded,
                  label: 'Version',
                  value: '1.0.0',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              'Made with care for researchers.',
              style: TextStyle(
                fontSize: 11,
                color: colorScheme.onSurface.withAlpha(130),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatRole(String roleId, String roleName) {
    final name = roleName.trim();
    if (name.isNotEmpty) return name;
    if (roleId.trim().isEmpty) return 'N/A';
    return roleId.trim();
  }

  Future<void> _confirmLogout(BuildContext context, AuthProvider auth) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
          'You will need to sign in again to sync your account with the backend.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );

    if (ok == true) {
      try {
        await GoogleSignIn().signOut();
      } catch (_) {
        // Email/password users may not have a Google session.
      }
      await FirebaseAuth.instance.signOut();
      await auth.clear();
      await AnalyticsService.instance.logLogout();

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Signed out')));
      }
    }
  }
}

class _NotificationMessagingSection extends StatefulWidget {
  const _NotificationMessagingSection({required this.userId});

  final String userId;

  @override
  State<_NotificationMessagingSection> createState() =>
      _NotificationMessagingSectionState();
}

class _NotificationMessagingSectionState
    extends State<_NotificationMessagingSection> {
  final _tokenController = TextEditingController();
  final _titleController = TextEditingController(text: 'ResearchHub test');
  final _bodyController = TextEditingController(
    text: 'Your Firebase Cloud Messaging notification is working.',
  );
  Timer? _autoSendTimer;
  String? _lastAutoSentToken;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final provider = context.read<NotificationProvider>();
    await provider.refreshToken();
    await provider.loadNotifications(widget.userId);
  }

  @override
  void dispose() {
    _autoSendTimer?.cancel();
    _tokenController.dispose();
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _copyToken(String token) async {
    await Clipboard.setData(ClipboardData(text: token));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('FCM token copied')));
  }

  Future<void> _pasteAndSend() async {
    final clipboard = await Clipboard.getData(Clipboard.kTextPlain);
    final token = clipboard?.text?.trim() ?? '';
    if (token.isEmpty) {
      _showMessage('Clipboard does not contain an FCM token.');
      return;
    }
    _tokenController.text = token;
    await _send();
  }

  void _autoSendPastedToken(String value) {
    _autoSendTimer?.cancel();
    final token = value.trim();
    if (token.length < 80 || token == _lastAutoSentToken) return;

    _autoSendTimer = Timer(const Duration(milliseconds: 700), () async {
      if (!mounted ||
          context.read<NotificationProvider>().isSending ||
          _tokenController.text.trim() != token) {
        return;
      }
      _lastAutoSentToken = token;
      await _send();
    });
  }

  Future<void> _send() async {
    final token = _tokenController.text.trim();
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();
    if (token.isEmpty || title.isEmpty || body.isEmpty) {
      _showMessage('FCM token, title and message are required.');
      return;
    }

    try {
      await context.read<NotificationProvider>().sendTestNotification(
        userId: widget.userId,
        token: token,
        title: title,
        body: body,
      );
      _showMessage('Notification sent successfully.');
    } catch (error) {
      _showMessage('Send failed: $error');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final provider = context.watch<NotificationProvider>();
    final token = provider.fcmToken;
    final recent = provider.notifications.take(3).toList();

    return _Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.key_rounded, color: colors.primary),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'This device FCM token',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  tooltip: 'Refresh token',
                  onPressed: provider.refreshToken,
                  icon: const Icon(Icons.refresh_rounded),
                ),
                IconButton(
                  tooltip: 'Copy token',
                  onPressed: token == null ? null : () => _copyToken(token),
                  icon: const Icon(Icons.copy_rounded),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: SelectableText(
                token ?? 'Token is not available on this platform yet.',
                maxLines: 4,
                style: const TextStyle(fontSize: 11),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _tokenController,
              onChanged: _autoSendPastedToken,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Destination FCM token (auto-send on paste)',
                hintText: 'Paste an FCM token here',
                helperText:
                    'Pasting a complete token sends the test automatically.',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _titleController,
              maxLength: 100,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _bodyController,
              minLines: 2,
              maxLines: 4,
              maxLength: 1000,
              decoration: const InputDecoration(labelText: 'Message'),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: provider.isSending ? null : _send,
                  icon: provider.isSending
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded),
                  label: const Text('Send test'),
                ),
                OutlinedButton.icon(
                  onPressed: provider.isSending ? null : _pasteAndSend,
                  icon: const Icon(Icons.content_paste_go_rounded),
                  label: const Text('Paste & send'),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Recent notifications',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NotificationsScreen(),
                    ),
                  ),
                  child: const Text('View all'),
                ),
              ],
            ),
            if (provider.isLoading && recent.isEmpty)
              const Center(child: CircularProgressIndicator())
            else if (recent.isEmpty)
              Text(
                'No notifications have been sent to this account yet.',
                style: TextStyle(color: colors.onSurfaceVariant),
              )
            else
              ...recent.map(
                (notification) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    notification.isRead
                        ? Icons.notifications_none_rounded
                        : Icons.notifications_active_rounded,
                    color: colors.primary,
                  ),
                  title: Text(
                    notification.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    notification.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.isDark,
    required this.daysActive,
    required this.searchesRun,
    required this.auth,
  });

  final bool isDark;
  final int daysActive;
  final int searchesRun;
  final AuthProvider auth;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final displayName = auth.isAuthenticated && auth.user != null
        ? (auth.user!.fullName.trim().isEmpty
              ? 'Researcher'
              : auth.user!.fullName)
        : 'Researcher';
    final subtitle = auth.isAuthenticated
        ? (auth.user!.email.trim().isEmpty ? 'Signed in' : auth.user!.email)
        : 'Local profile · activity only';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: isDark
              ? [
                  colorScheme.primary.withAlpha(50),
                  colorScheme.secondary.withAlpha(35),
                ]
              : [
                  colorScheme.primary.withAlpha(38),
                  colorScheme.secondary.withAlpha(28),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: colorScheme.primary.withAlpha(50)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                colors: [colorScheme.primary, colorScheme.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Icon(
              Icons.person_rounded,
              size: 30,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurface.withAlpha(150),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _Pill(
                      icon: Icons.calendar_today_rounded,
                      label: '$daysActive d',
                      colorScheme: colorScheme,
                    ),
                    const SizedBox(width: 8),
                    _Pill(
                      icon: Icons.travel_explore_rounded,
                      label: '$searchesRun searches',
                      colorScheme: colorScheme,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.icon,
    required this.label,
    required this.colorScheme,
  });

  final IconData icon;
  final String label;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colorScheme.surface.withAlpha(190),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outline.withAlpha(30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: colorScheme.onSurface.withAlpha(180)),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurface.withAlpha(180),
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: colorScheme.surface,
        border: Border.all(color: colorScheme.outline.withAlpha(20)),
      ),
      child: child,
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      leading: Icon(icon, color: colorScheme.primary, size: 20),
      title: Text(
        label,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      ),
      trailing: Text(
        value,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurface.withAlpha(180),
        ),
      ),
    );
  }
}
