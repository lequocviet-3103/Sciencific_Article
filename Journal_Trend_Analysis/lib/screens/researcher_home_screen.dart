import 'package:flutter/material.dart';
import 'compare_trend_screen.dart';
import 'db_dashboard_screen.dart';
import 'emerging_topics_screen.dart';
import 'profile_screen.dart';
import 'search_screen.dart';
import 'topics_screen.dart';
import 'trend_analysis_screen.dart';

/// Bottom-navigation shell shown after a Researcher logs in.
/// Researchers get deeper analytics: trend analysis, compare keywords,
/// emerging topics discovery, dashboard — on top of the shared screens.
class ResearcherHomeScreen extends StatefulWidget {
  const ResearcherHomeScreen({super.key});

  @override
  State<ResearcherHomeScreen> createState() => _ResearcherHomeScreenState();
}

class _ResearcherHomeScreenState extends State<ResearcherHomeScreen> {
  int _index = 0;

  final _tabs = const [
    TopicsScreen(),
    _AnalyticsTab(),
    DbDashboardScreen(),
    SearchScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: 'Search',
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

/// Analytics hub: entry points to Trend Analysis, Compare Trends,
/// and Emerging Topics — the researcher-specific features.
class _AnalyticsTab extends StatelessWidget {
  const _AnalyticsTab();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final items = [
      _AnalyticsItem(
        icon: Icons.show_chart,
        title: 'Trend Analysis',
        subtitle: 'Publications per year for your search results',
        color: colorScheme.primary,
        builder: (_) => const TrendAnalysisScreen(),
      ),
      _AnalyticsItem(
        icon: Icons.compare_arrows,
        title: 'Compare Trends',
        subtitle: 'Side-by-side multi-keyword trend comparison',
        color: Colors.pink.shade600,
        builder: (_) => const CompareTrendScreen(),
      ),
      _AnalyticsItem(
        icon: Icons.trending_up,
        title: 'Emerging Topics',
        subtitle: 'Topics with the highest recent growth',
        color: Colors.orange.shade700,
        builder: (_) => const EmergingTopicsScreen(),
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final item = items[i];
          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: item.builder),
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: colorScheme.surface,
                border: Border.all(color: colorScheme.outline.withAlpha(20)),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withAlpha(8),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: item.color.withAlpha(25),
                    ),
                    child: Icon(item.icon, color: item.color, size: 26),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.subtitle,
                          style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.onSurface.withAlpha(150),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right,
                      color: colorScheme.onSurface.withAlpha(80)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AnalyticsItem {
  const _AnalyticsItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.builder,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final WidgetBuilder builder;
}
