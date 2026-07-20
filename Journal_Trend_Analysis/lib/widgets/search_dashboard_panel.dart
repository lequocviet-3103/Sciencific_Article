import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../screens/journals_analysis_screen.dart';
import '../screens/keywords_analysis_screen.dart';
import '../screens/publication_detail_screen.dart';
import '../services/paper_search_service.dart';
import '../services/research_insights_service.dart';
import '../utils/number_format.dart';

class SearchDashboardPanel extends StatefulWidget {
  const SearchDashboardPanel({super.key, required this.query, this.topicId});

  final String query;
  final String? topicId;

  @override
  State<SearchDashboardPanel> createState() => _SearchDashboardPanelState();
}

class _SearchDashboardPanelState extends State<SearchDashboardPanel> {
  final _service = ResearchInsightsService();
  late Future<SearchDashboardData> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void didUpdateWidget(covariant SearchDashboardPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query ||
        oldWidget.topicId != widget.topicId) {
      _reload();
    }
  }

  void _reload() {
    _future = _service.getDashboard(
      topicId: widget.topicId,
      query: widget.query,
    );
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SearchDashboardData>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return Center(
            child: FilledButton.icon(
              onPressed: () => setState(_reload),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry analytics'),
            ),
          );
        }
        return _DashboardContent(
          data: snapshot.data!,
          onRefresh: () async => setState(_reload),
        );
      },
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({required this.data, required this.onRefresh});
  final SearchDashboardData data;
  final Future<void> Function() onRefresh;

  Future<void> _openPaper(BuildContext context, InsightPaper paper) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final service = PaperSearchService();
    try {
      final full = await service.fetchWorkById(paper.paperId);
      if (!context.mounted) return;
      navigator.push(
        MaterialPageRoute(
          builder: (_) => PublicationDetailScreen(publication: full),
        ),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not open publication')),
      );
    } finally {
      service.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final topPaper = data.topPapers.isEmpty ? null : data.topPapers.first;
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        children: [
          if (data.publicationsByYear.isNotEmpty) ...[
            const _SectionTitle('Publication Trend'),
            const SizedBox(height: 12),
            _TrendCard(points: data.publicationsByYear),
            const SizedBox(height: 28),
          ],
          const _SectionTitle('Key Analytics'),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.45,
            children: [
              _KpiCard(
                icon: Icons.library_books_outlined,
                label: 'Total Publications',
                value: formatCompact(data.totalPublications),
              ),
              _KpiCard(
                icon: Icons.format_quote,
                label: 'Avg Citations',
                value: data.avgCitations.toStringAsFixed(1),
              ),
              _KpiCard(
                icon: Icons.auto_graph,
                label: 'Total Citations',
                value: formatCompact(data.totalCitations),
              ),
              _KpiCard(
                icon: Icons.people_outline,
                label: 'Unique Authors',
                value: formatCompact(data.uniqueAuthors),
              ),
            ],
          ),
          if (topPaper != null) ...[
            const SizedBox(height: 28),
            const _SectionTitle('Most Influential Paper'),
            const SizedBox(height: 12),
            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => _openPaper(context, topPaper),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.amber.withAlpha(18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.amber.withAlpha(90)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber),
                        const SizedBox(width: 8),
                        Text(
                          '${formatInt(topPaper.citations)} citations',
                          style: TextStyle(
                            color: Colors.orange.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Icon(Icons.chevron_right, color: cs.outline),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      topPaper.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                    if (topPaper.year != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Published: ${topPaper.year}',
                        style: TextStyle(color: cs.outline),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
          if (data.fieldBreakdown.isNotEmpty) ...[
            const SizedBox(height: 28),
            const _SectionTitle('Overview by Field'),
            const SizedBox(height: 12),
            _FieldCard(
              items: data.fieldBreakdown,
              total: data.totalPublications,
            ),
          ],
          const SizedBox(height: 28),
          const _SectionTitle('Explore Analysis'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _AnalysisLink(
                  icon: Icons.menu_book_outlined,
                  label: 'Journals',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const JournalsAnalysisScreen(),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _AnalysisLink(
                  icon: Icons.key_outlined,
                  label: 'Keywords',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const KeywordsAnalysisScreen(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
  );
}

class _TrendCard extends StatelessWidget {
  const _TrendCard({required this.points});
  final List<InsightYearPoint> points;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final maxCount = points.fold<int>(
      1,
      (max, p) => p.count > max ? p.count : max,
    );
    return Container(
      height: 260,
      padding: const EdgeInsets.fromLTRB(12, 20, 18, 12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.outline.withAlpha(25)),
      ),
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxCount.toDouble() + 1,
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: cs.outline.withAlpha(25), strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, _) => Text(
                  '${value.toInt()}',
                  style: TextStyle(fontSize: 10, color: cs.outline),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: points.length > 6
                    ? (points.length / 4).ceilToDouble()
                    : 1,
                getTitlesWidget: (value, _) {
                  final i = value.toInt();
                  if (i < 0 || i >= points.length) return const SizedBox();
                  return Text(
                    '${points[i].year}',
                    style: TextStyle(fontSize: 9, color: cs.outline),
                  );
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: [
                for (var i = 0; i < points.length; i++)
                  FlSpot(i.toDouble(), points[i].count.toDouble()),
              ],
              color: cs.primary,
              isCurved: true,
              barWidth: 3,
              dotData: FlDotData(show: points.length <= 8),
              belowBarData: BarAreaData(
                show: true,
                color: cs.primary.withAlpha(28),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withAlpha(180),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: cs.primary),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: cs.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: cs.primary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldCard extends StatelessWidget {
  const _FieldCard({required this.items, required this.total});
  final List<InsightCount> items;
  final int total;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final colors = <Color>[
      const Color(0xFFB7BCFF),
      const Color(0xFFD9DBEA),
      const Color(0xFFE5BCD3),
      const Color(0xFF8A5CF6),
      const Color(0xFF4DB5D2),
      const Color(0xFFF2A93B),
    ];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.outline.withAlpha(25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.category, color: cs.primary),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Overview by Field',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                '${items.length} fields · $total papers',
                style: TextStyle(fontSize: 11, color: cs.outline),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Each paper counted under its primary topic field',
            style: TextStyle(fontSize: 12, color: cs.outline),
          ),
          const SizedBox(height: 20),
          for (var i = 0; i < items.length; i++) ...[
            Row(
              children: [
                Container(
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(
                    color: colors[i % colors.length],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    items[i].name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  '${items[i].count} papers',
                  style: TextStyle(fontSize: 12, color: cs.outline),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: total == 0 ? 0 : items[i].count / total,
                minHeight: 7,
                color: colors[i % colors.length],
                backgroundColor: cs.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }
}

class _AnalysisLink extends StatelessWidget {
  const _AnalysisLink({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: cs.outline.withAlpha(25)),
        ),
        child: Row(
          children: [
            Icon(icon, color: cs.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const Icon(Icons.chevron_right, size: 18),
          ],
        ),
      ),
    );
  }
}
