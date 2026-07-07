import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/dashboard_provider.dart';
import '../utils/number_format.dart';
import '../widgets/empty_view.dart';
import '../widgets/field_breakdown_card.dart';
import '../widgets/method_explainer_card.dart';
import '../widgets/modern_app_bar.dart';
import '../widgets/stat_tile.dart';
import 'publication_detail_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dash = context.watch<DashboardProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    if (!dash.isReady) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F0F1A) : const Color(0xFFF0F2F8),
        appBar: const ModernAppBar(title: 'Research Dashboard'),
        body: const Center(
          child: EmptyView(
            message: 'Run a search first to see dashboard.',
            icon: Icons.dashboard,
          ),
        ),
      );
    }

    final s = dash.stats;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F1A) : const Color(0xFFF0F2F8),
      appBar: ModernAppBar(
        title: 'Research Dashboard',
        subtitle: dash.searchQuery.isEmpty
            ? 'Your search analytics'
            : 'Analytics for "${dash.searchQuery}"',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Data provenance banner
            _DataProvenanceBanner(
              loadedCount: s.totalPublications,
              apiTotalCount: dash.apiTotalCount,
              query: dash.searchQuery,
            ),

            const SizedBox(height: 18),

            // KPI grid: 2 columns
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.2,
              children: [
                StatTile(
                  icon: Icons.library_books,
                  label: 'Total Publications',
                  value: formatInt(s.totalPublications),
                  subtitle: dash.apiTotalCount > s.totalPublications
                      ? 'of ${formatInt(dash.apiTotalCount)} matched'
                      : null,
                ),
                StatTile(
                  icon: Icons.format_quote,
                  label: 'Avg Citations',
                  value: s.averageCitations.toStringAsFixed(1),
                ),
                StatTile(
                  icon: Icons.calendar_today,
                  label: 'Most Active Year',
                  value: s.mostActiveYear?.toString() ?? 'N/A',
                  subtitle: s.mostActiveYear != null
                      ? '${formatInt(s.mostActiveYearCount)} papers'
                      : null,
                ),
                StatTile(
                  icon: Icons.menu_book,
                  label: 'Top Journal',
                  value: _truncate(s.topJournal ?? 'N/A', 18),
                  subtitle: s.topJournal != null
                      ? '${formatInt(s.topJournalCount)} papers'
                      : null,
                ),
                StatTile(
                  icon: Icons.people_alt,
                  label: 'Unique Authors',
                  value: formatInt(s.totalUniqueAuthors),
                  subtitle: 'across all publications',
                ),
                StatTile(
                  icon: Icons.star,
                  label: 'Top Author',
                  value: _truncate(s.topAuthor ?? 'N/A', 18),
                  subtitle: s.topAuthor != null
                      ? '${formatInt(s.topAuthorCount)} papers'
                      : null,
                ),
              ],
            ),

            const SizedBox(height: 28),

            // Overview by field
            Text(
              'Overview by Field',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Publications grouped by their primary topic field',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurface.withAlpha(140),
              ),
            ),
            const SizedBox(height: 12),
            FieldBreakdownCard(fieldCounts: s.fieldBreakdown),

            const SizedBox(height: 28),

            // Top Authors with expandable evidence
            AuthorsEvidenceCard(
              authors: dash.topAuthors,
              onSampleTap: (id) {
                if (dash.topCited.isEmpty) return;
                final pub = dash.topCited.firstWhere(
                  (p) => p.id == id,
                  orElse: () => dash.topCited.first,
                );
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PublicationDetailScreen(publication: pub),
                  ),
                );
              },
            ),

            const SizedBox(height: 28),

            // Methodology / "how was this computed" card
            MethodExplainerCard(
              loadedCount: s.totalPublications,
              apiTotalCount: dash.apiTotalCount,
              uniqueAuthors: s.totalUniqueAuthors,
              totalAuthorships: s.totalAuthorships,
              distinctFields: s.fieldBreakdown.length,
              totalTopics: s.fieldBreakdown.values.fold<int>(0, (a, b) => a + b),
              query: dash.searchQuery,
            ),

            const SizedBox(height: 28),

            // Most influential paper card
            Text(
              'Most Influential Paper',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                if (dash.topCited.isEmpty) return;
                final pub = dash.topCited.firstWhere(
                  (p) => p.id == s.mostInfluentialId,
                  orElse: () => dash.topCited.first,
                );
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PublicationDetailScreen(publication: pub),
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [
                      Colors.amber.withAlpha(30),
                      Colors.orange.withAlpha(15),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: Colors.amber.withAlpha(60),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          '${formatInt(s.mostInfluentialCitations)} citations',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade800,
                            fontSize: 15,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.chevron_right,
                          color: colorScheme.onSurface.withAlpha(100),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      s.mostInfluentialTitle ?? 'N/A',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface,
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (s.mostInfluentialYear != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Published: ${s.mostInfluentialYear}',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurface.withAlpha(140),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 28),

            // Top cited papers
            Text(
              'Top 5 Cited Papers',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),

            ...dash.topCited.take(5).toList().asMap().entries.map((entry) {
              final idx = entry.key;
              final p = entry.value;
              final rank = idx + 1;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: colorScheme.surface,
                  border: Border.all(
                    color: colorScheme.outline.withAlpha(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withAlpha(8),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 4,
                  ),
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: rank == 1
                            ? [Colors.amber, Colors.orange]
                            : rank == 2
                                ? [Colors.grey.shade400, Colors.grey.shade500]
                                : rank == 3
                                    ? [Colors.brown.shade400, Colors.brown.shade600]
                                    : [
                                        colorScheme.primary.withAlpha(60),
                                        colorScheme.secondary.withAlpha(60),
                                      ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$rank',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  title: Text(
                    p.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface,
                      height: 1.3,
                    ),
                  ),
                  subtitle: Text(
                    '${p.year ?? 'N/A'} • ${formatInt(p.citedByCount)} citations',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurface.withAlpha(140),
                    ),
                  ),
                  trailing: Icon(
                    Icons.chevron_right,
                    color: colorScheme.onSurface.withAlpha(80),
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PublicationDetailScreen(publication: p),
                    ),
                  ),
                ),
              );
            }),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  String _truncate(String s, int n) =>
      s.length > n ? '${s.substring(0, n)}…' : s;
}

/// Small banner at the top of the dashboard that makes it clear where
/// the numbers come from. Useful for explaining to reviewers/teachers
/// that the analytics are computed locally on the data returned by
/// OpenAlex, not a separate estimate.
class _DataProvenanceBanner extends StatelessWidget {
  const _DataProvenanceBanner({
    required this.loadedCount,
    required this.apiTotalCount,
    required this.query,
  });

  final int loadedCount;
  final int apiTotalCount;
  final String query;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final capped = apiTotalCount > loadedCount && apiTotalCount > 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: colorScheme.surfaceContainerHighest.withAlpha(80),
        border: Border.all(
          color: colorScheme.outline.withAlpha(40),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.verified_outlined,
            size: 18,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Computed locally from OpenAlex data',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  capped
                      ? 'Showing $loadedCount of ${formatInt(apiTotalCount)} matches'
                          '${query.isEmpty ? '' : ' for "$query"'}'
                          ' (rest not loaded to keep the app responsive).'
                      : 'Showing all $loadedCount matches'
                          '${query.isEmpty ? '' : ' for "$query"'}.',
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurface.withAlpha(160),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
