import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.user != null) {
        context.read<NotificationProvider>().loadNotifications(auth.user!.userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final auth = context.read<AuthProvider>();
              if (auth.user != null) {
                context.read<NotificationProvider>().loadNotifications(auth.user!.userId);
              }
            },
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: colorScheme.error),
                  const SizedBox(height: 16),
                  Text(provider.error!, style: TextStyle(color: colorScheme.error)),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () {
                      final auth = context.read<AuthProvider>();
                      if (auth.user != null) {
                        provider.loadNotifications(auth.user!.userId);
                      }
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (provider.notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 64, color: colorScheme.outline),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: colorScheme.outline),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              final auth = context.read<AuthProvider>();
              if (auth.user != null) {
                await provider.loadNotifications(auth.user!.userId);
              }
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: provider.notifications.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final n = provider.notifications[index];
                return Card(
                  elevation: 0,
                  color: n.isRead
                      ? colorScheme.surfaceContainerLow
                      : colorScheme.primaryContainer.withValues(alpha: 0.3),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: n.isRead
                          ? colorScheme.surfaceContainerHighest
                          : colorScheme.primary,
                      child: Icon(
                        Icons.notifications,
                        color: n.isRead ? colorScheme.outline : Colors.white,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      n.title,
                      style: TextStyle(
                        fontWeight: n.isRead ? FontWeight.normal : FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (n.content.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(n.content, maxLines: 2, overflow: TextOverflow.ellipsis),
                        ],
                        if (n.createdAt != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            _formatTime(n.createdAt!),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: colorScheme.outline,
                                ),
                          ),
                        ],
                      ],
                    ),
                    onTap: () async {
                      if (!n.isRead) {
                        await provider.markAsRead(n.notificationId);
                      }
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}
