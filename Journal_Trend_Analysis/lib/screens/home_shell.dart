import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/bookmark_provider.dart';
import '../providers/notification_provider.dart';
import 'bookmarks_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import 'search_screen.dart';
import 'topics_screen.dart';

/// Persistent bottom-navigation shell shown after a Customer logs in.
/// Each tab keeps its own [Scaffold]/[AppBar]; only the body and the
/// nav bar are swapped, so per-tab scroll position and provider state
/// survive switching tabs (via [IndexedStack]).
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  late final List<Widget> _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = [
      const TopicsScreen(),
      SearchScreen(onBack: _goHome),
      const BookmarksScreen(),
      const NotificationsScreen(),
      const ProfileScreen(),
    ];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<NotificationProvider>().initPush();
      final userId = context.read<AuthProvider>().user?.userId;
      if (userId != null) {
        context.read<NotificationProvider>().loadNotifications(userId);
      }
    });
  }

  void _goHome() {
    if (mounted && _index != 0) setState(() => _index = 0);
  }

  @override
  Widget build(BuildContext context) {
    final bookmarks = context.watch<BookmarkProvider>();
    final notifications = context.watch<NotificationProvider>();

    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          const NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: 'Search',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: bookmarks.hasBookmarks,
              label: Text('${bookmarks.bookmarks.length}'),
              child: const Icon(Icons.bookmark_border),
            ),
            selectedIcon: const Icon(Icons.bookmark),
            label: 'Bookmarks',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: notifications.unreadCount > 0,
              label: Text('${notifications.unreadCount}'),
              child: const Icon(Icons.notifications_outlined),
            ),
            selectedIcon: const Icon(Icons.notifications),
            label: 'Alerts',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
