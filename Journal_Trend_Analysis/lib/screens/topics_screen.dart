import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../models/publication.dart';
import '../models/topic.dart';
import '../providers/bookmark_provider.dart';
import '../providers/recent_provider.dart';
import '../providers/search_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/topics_provider.dart';
import '../services/backend_paper_service.dart';
import '../utils/debouncer.dart';
import '../utils/number_format.dart';
import '../widgets/empty_view.dart';
import '../widgets/error_view.dart';
import '../widgets/recent_sections.dart';
import '../widgets/topic_card.dart';
import 'bookmarks_screen.dart';
import 'database_papers_screen.dart';
import 'db_dashboard_screen.dart';
import 'publication_detail_screen.dart';
import 'reports_screen.dart';
import 'search_screen.dart';
import 'trend_analysis_screen.dart';

class TopicsScreen extends StatefulWidget {
  const TopicsScreen({super.key});

  @override
  State<TopicsScreen> createState() => _TopicsScreenState();
}

class _TopicsScreenState extends State<TopicsScreen> {
  final _searchController = TextEditingController();
  final _debouncer = Debouncer();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final topics = context.read<TopicsProvider>();
      if (topics.status == TopicsStatus.idle) {
        topics.loadFeatured();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  void _onTopicSelected(Topic topic) {
    HapticFeedback.selectionClick();
    FocusScope.of(context).unfocus();
    final search = context.read<SearchProvider>();
    context.read<RecentProvider>().trackTopic(topic);
    // Reset provider state before navigating so the new screen always
    // starts from a clean slate and the header shows the topic name.
    search.clear();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SearchScreen(
          topic: topic,
          initialQuery: topic.displayName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topics = context.watch<TopicsProvider>();
    final theme = context.watch<ThemeProvider>();
    final bookmarks = context.watch<BookmarkProvider>();
    final isDark = theme.isDark;
    final colorScheme = Theme.of(context).colorScheme;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark
          ? SystemUiOverlayStyle.light.copyWith(
              statusBarColor: Colors.transparent,
            )
          : SystemUiOverlayStyle.dark.copyWith(
              statusBarColor: Colors.transparent,
            ),
      child: Scaffold(
        backgroundColor:
            isDark ? const Color(0xFF0F0F1A) : const Color(0xFFF0F2F8),
        body: Stack(
          children: [
            // Background gradient blobs
            Positioned(
              top: -100,
              right: -80,
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      colorScheme.primary.withAlpha(50),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 200,
              left: -120,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      colorScheme.secondary.withAlpha(35),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            SafeArea(
              child: Column(
                children: [
                  _buildAppBar(context, theme, bookmarks),
                  _buildSearchBox(context, topics, isDark),
                  _buildQuickLinks(context),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _buildBody(context, topics, isDark),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(
    BuildContext context,
    ThemeProvider theme,
    BookmarkProvider bookmarks,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
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
                        Icons.auto_stories_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'ResearchHub',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Pick a topic to explore research',
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurface.withAlpha(150),
                  ),
                ),
              ],
            ),
          ),
          _GlassIconButton(
            icon: Icon(
              theme.isDark ? Icons.light_mode : Icons.dark_mode,
              size: 20,
            ),
            onTap: () => theme.toggle(),
          ),
          const SizedBox(width: 8),
          _GlassIconButton(
            icon: const Icon(
              Icons.person_outline_rounded,
              size: 20,
            ),
            onTap: () => Navigator.pushNamed(context, '/profile'),
          ),
          const SizedBox(width: 8),
          _GlassIconButton(
            icon: Badge(
              isLabelVisible: bookmarks.hasBookmarks,
              label: Text(bookmarks.bookmarks.length.toString()),
              child: Icon(
                bookmarks.hasBookmarks
                    ? Icons.bookmark
                    : Icons.bookmark_border,
                size: 20,
              ),
            ),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BookmarksScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickLinks(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final links = <_QuickLink>[
      _QuickLink(
        icon: Icons.dashboard_outlined,
        label: 'Dashboard',
        builder: (_) => const DbDashboardScreen(),
      ),
      _QuickLink(
        icon: Icons.trending_up_rounded,
        label: 'Trends',
        builder: (_) => const TrendAnalysisScreen(),
      ),
      _QuickLink(
        icon: Icons.assessment_outlined,
        label: 'Reports',
        builder: (_) => const ReportsScreen(),
      ),
      _QuickLink(
        icon: Icons.storage_outlined,
        label: 'Database',
        builder: (_) => const DatabasePapersScreen(),
      ),
    ];

    return SizedBox(
      height: 82,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
        itemCount: links.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final link = links[i];
          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: link.builder),
            ),
            child: Container(
              width: 84,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: colorScheme.surface,
                border: Border.all(color: colorScheme.outline.withAlpha(30)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(link.icon, size: 22, color: colorScheme.primary),
                  const SizedBox(height: 6),
                  Text(
                    link.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchBox(
    BuildContext context,
    TopicsProvider topics,
    bool isDark,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withAlpha(15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (v) {
            _debouncer.call(() {
              topics.searchTopics(v);
            });
          },
          textInputAction: TextInputAction.search,
          style: TextStyle(
            fontSize: 15,
            color: colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            hintText: 'Search topics (e.g. AI, Quantum, Bio...)',
            hintStyle: TextStyle(
              color: colorScheme.onSurface.withAlpha(100),
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: colorScheme.primary,
              size: 22,
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.close,
                      color: colorScheme.onSurface.withAlpha(150),
                    ),
                    onPressed: () {
                      _searchController.clear();
                      topics.loadFeatured();
                      setState(() {});
                    },
                  )
                : null,
            filled: true,
            fillColor: isDark
                ? const Color(0xFF1E1E2E).withAlpha(200)
                : Colors.white.withAlpha(240),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(
                color: colorScheme.outline.withAlpha(30),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(
                color: colorScheme.primary.withAlpha(100),
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, TopicsProvider topics, bool isDark) {
    // In search mode only: show full-screen loading/error/empty states
    if (topics.query.isNotEmpty) {
      if (topics.status == TopicsStatus.error) {
        return ErrorView(
          key: const ValueKey('topics_error'),
          message: topics.errorMessage ?? 'Failed to load topics',
          onRetry: () => topics.loadFeatured(),
        );
      }
      if (topics.status == TopicsStatus.loading && topics.topics.isEmpty) {
        return _TopicsShimmer(key: const ValueKey('topics_loading'), isDark: isDark);
      }
      if (topics.topics.isEmpty) {
        return EmptyView(
          key: const ValueKey('topics_empty'),
          icon: Icons.search_off,
          message: 'No topics match "${topics.query}".',
        );
      }
    }

    // Home mode: always show the DB section even while topics are loading.
    final grouped = topics.topics.isNotEmpty ? topics.grouped() : <String, List<Topic>>{};
    final entries = grouped.entries.toList();
    final recents = context.watch<RecentProvider>();
    final hasRecents =
        recents.publications.isNotEmpty || recents.topics.isNotEmpty;
    final showOverview = topics.query.isEmpty;
    final headerCount = (showOverview ? 1 : 0) + (hasRecents ? 1 : 0);
    final totalItems = entries.length + headerCount;

    return RefreshIndicator(
      key: const ValueKey('topics_success'),
      onRefresh: () => topics.loadFeatured(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        itemCount: totalItems,
        itemBuilder: (context, index) {
          var cursor = index;
          if (showOverview) {
            if (cursor == 0) {
              return const Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: _DbHomeSection(),
              );
            }
            cursor -= 1;
          }
          if (hasRecents) {
            if (cursor == 0) {
              return const Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: RecentSections(),
              );
            }
            cursor -= 1;
          }
          if (entries.isEmpty) {
            // Header only — render a small empty hint below the
            // header so the screen is not completely blank.
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: EmptyView(
                icon: Icons.search_off,
                message:
                    'No topics match your filter. Try a different search term.',
              ),
            );
          }
          final entry = entries[cursor];
          return _TopicSection(
            title: entry.key,
            topics: entry.value,
            onTopicTap: _onTopicSelected,
          );
        },
      ),
    );
  }
}

/// DB-backed home section: stats + latest papers from the backend.
class _DbHomeSection extends StatefulWidget {
  const _DbHomeSection();

  @override
  State<_DbHomeSection> createState() => _DbHomeSectionState();
}

class _DbHomeSectionState extends State<_DbHomeSection> {
  final _service = BackendPaperService();
  Map<String, int>? _stats;
  List<Publication> _latest = [];
  bool _loading = true;

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
    try {
      final results = await Future.wait([
        _service.getStats(),
        _service.getLatestPapers(take: 10),
      ]);
      if (mounted) {
        setState(() {
          _stats = results[0] as Map<String, int>;
          _latest = results[1] as List<Publication>;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── DB Stats Card ──
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: isDark
                  ? [colorScheme.primary.withAlpha(50), colorScheme.secondary.withAlpha(35)]
                  : [colorScheme.primary.withAlpha(35), colorScheme.secondary.withAlpha(25)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: colorScheme.primary.withAlpha(50)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: colorScheme.surface.withAlpha(200),
                    ),
                    child: Icon(Icons.storage_rounded, color: colorScheme.primary, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Research Database',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withAlpha(20),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Live Stats',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (_loading)
                const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
              else if (_stats != null)
                Row(
                  children: [
                    _StatTile(label: 'Papers', value: formatCompact(_stats!['paperCount'] ?? 0), icon: Icons.article_outlined, color: colorScheme.primary, colorScheme: colorScheme),
                    const SizedBox(width: 8),
                    _StatTile(label: 'Authors', value: formatCompact(_stats!['authorCount'] ?? 0), icon: Icons.people_outline, color: Colors.purple, colorScheme: colorScheme),
                    const SizedBox(width: 8),
                    _StatTile(label: 'Journals', value: formatCompact(_stats!['journalCount'] ?? 0), icon: Icons.menu_book_outlined, color: Colors.teal, colorScheme: colorScheme),
                    const SizedBox(width: 8),
                    _StatTile(label: 'Topics', value: formatCompact(_stats!['topicCount'] ?? 0), icon: Icons.label_outline, color: Colors.orange, colorScheme: colorScheme),
                  ],
                )
              else
                Text('Could not load stats', style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withAlpha(130))),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // ── Latest Papers Section ──
        if (_latest.isNotEmpty) ...[
          Row(
            children: [
              Container(
                width: 4, height: 18,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  gradient: LinearGradient(
                    colors: [colorScheme.primary, colorScheme.secondary],
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Latest from Database',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorScheme.onSurface, letterSpacing: -0.2),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DatabasePapersScreen())),
                child: const Text('See all'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 160,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _latest.length,
              separatorBuilder: (context, i) => const SizedBox(width: 12),
              itemBuilder: (context, i) {
                final pub = _latest[i];
                return GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => PublicationDetailScreen(publication: pub)),
                  ),
                  child: Container(
                    width: 220,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: colorScheme.outline.withAlpha(30)),
                      boxShadow: [
                        BoxShadow(color: colorScheme.shadow.withAlpha(8), blurRadius: 8, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                pub.year?.toString() ?? 'N/A',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colorScheme.onPrimaryContainer),
                              ),
                            ),
                            const Spacer(),
                            Icon(Icons.format_quote, size: 13, color: colorScheme.onSurface.withAlpha(100)),
                            const SizedBox(width: 2),
                            Text(
                              formatCompact(pub.citedByCount),
                              style: TextStyle(fontSize: 11, color: colorScheme.onSurface.withAlpha(120), fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Text(
                            pub.title,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, height: 1.3, color: colorScheme.onSurface),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          pub.journal.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11, color: colorScheme.onSurface.withAlpha(140)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value, required this.icon, required this.color, required this.colorScheme});
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: colorScheme.surface.withAlpha(190),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(40)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
            Text(label, style: TextStyle(fontSize: 9, color: colorScheme.onSurface.withAlpha(150)), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

class _TopicSection extends StatelessWidget {
  const _TopicSection({
    required this.title,
    required this.topics,
    required this.onTopicTap,
  });

  final String title;
  final List<Topic> topics;
  final void Function(Topic) onTopicTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 16, 4, 12),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primary,
                      colorScheme.secondary,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '· ${topics.length}',
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurface.withAlpha(120),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        ...topics.map(
          (t) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: TopicCard(topic: t, onTap: () => onTopicTap(t)),
          ),
        ),
      ],
    );
  }
}

class _TopicsShimmer extends StatelessWidget {
  const _TopicsShimmer({super.key, required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
      highlightColor: isDark ? Colors.grey.shade700 : Colors.grey.shade100,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        itemCount: 6,
        itemBuilder: (_, _) => Container(
          height: 86,
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }
}

class _QuickLink {
  const _QuickLink({
    required this.icon,
    required this.label,
    required this.builder,
  });

  final IconData icon;
  final String label;
  final WidgetBuilder builder;
}

class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({required this.icon, required this.onTap});

  final Widget icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: colorScheme.surfaceContainerHighest.withAlpha(150),
          border: Border.all(
            color: colorScheme.outline.withAlpha(40),
          ),
        ),
        child: Center(child: icon),
      ),
    );
  }
}
