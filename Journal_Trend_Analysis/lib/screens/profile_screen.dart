import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/modern_app_bar.dart';

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
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
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
                Divider(
                  height: 1,
                  color: colorScheme.outline.withAlpha(20),
                ),
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
                    value: auth.user!.email.isNotEmpty ? auth.user!.email : 'Not set',
                  ),
                  Divider(
                    height: 1,
                    color: colorScheme.outline.withAlpha(20),
                  ),
                  _StatRow(
                    icon: Icons.badge_rounded,
                    label: 'Role',
                    value: _formatRole(auth.user!.roleId, auth.user!.roleName),
                  ),
                  Divider(
                    height: 1,
                    color: colorScheme.outline.withAlpha(20),
                  ),
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
                Divider(
                  height: 1,
                  color: colorScheme.outline.withAlpha(20),
                ),
                _StatRow(
                  icon: Icons.cloud_outlined,
                  label: 'Data source',
                  value: 'OpenAlex',
                ),
                Divider(
                  height: 1,
                  color: colorScheme.outline.withAlpha(20),
                ),
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
      await FirebaseAuth.instance.signOut();
      await auth.clear();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Signed out')),
        );
      }
    }
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
        ? (auth.user!.fullName.trim().isEmpty ? 'Researcher' : auth.user!.fullName)
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
                colors: [
                  colorScheme.primary,
                  colorScheme.secondary,
                ],
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
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 4,
      ),
      leading: Icon(icon, color: colorScheme.primary, size: 20),
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
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
