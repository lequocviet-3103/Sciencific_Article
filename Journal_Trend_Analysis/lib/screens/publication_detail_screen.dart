import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/publication.dart';
import '../providers/bookmark_provider.dart';
import '../providers/recent_provider.dart';
import '../services/paper_search_service.dart';
import '../utils/number_format.dart';
import '../widgets/modern_app_bar.dart';

class PublicationDetailScreen extends StatefulWidget {
  const PublicationDetailScreen({super.key, required this.publication});

  final Publication publication;

  @override
  State<PublicationDetailScreen> createState() =>
      _PublicationDetailScreenState();
}

class _PublicationDetailScreenState extends State<PublicationDetailScreen> {
  late Publication _publication;
  bool _isLoadingFull = false;

  @override
  void initState() {
    super.initState();
    _publication = widget.publication;
    _fetchFullDetails();
  }

  Future<void> _fetchFullDetails() async {
    // Summary responses can contain authors/abstract while still omitting
    // topics. Always refresh a valid backend paper id from the detail API.
    if (_publication.id.isEmpty) return;

    setState(() => _isLoadingFull = true);

    final service = PaperSearchService();
    try {
      final full = await service.fetchWorkById(_publication.id);
      if (mounted) {
        setState(() {
          _publication = full;
          _isLoadingFull = false;
        });
      }
    } catch (_) {
      // Silently fall back — the screen still renders with whatever data was
      // already loaded from the search result. Abstract shows "not available".
      if (mounted) setState(() => _isLoadingFull = false);
    } finally {
      service.dispose();
    }
  }

  Future<void> _openDoi(BuildContext context) async {
    final doi = _publication.doi;
    if (doi == null || doi.isEmpty) return;
    final url = Uri.parse('https://doi.org/$doi');
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open DOI link')),
        );
      }
    }
  }

  void _sharePublication() {
    final doi = _publication.doi != null
        ? 'https://doi.org/${_publication.doi}'
        : '';
    final text =
        '${_publication.title}\n'
        'Year: ${_publication.year ?? 'N/A'}  |  Citations: ${formatInt(_publication.citedByCount)}\n'
        'Journal: ${_publication.journal.name}\n'
        '$doi';
    Share.share(text, subject: _publication.title);
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      context.read<RecentProvider>().trackPublication(_publication);
    });

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bookmarks = context.watch<BookmarkProvider>();
    final isBookmarked = bookmarks.isBookmarked(_publication.id);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F0F1A)
          : const Color(0xFFF0F2F8),
      appBar: ModernAppBar(
        title: 'Publication Detail',
        actions: [
          _DetailActionButton(
            icon: Icon(
              isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              color: isBookmarked ? colorScheme.primary : null,
            ),
            tooltip: isBookmarked ? 'Remove bookmark' : 'Bookmark',
            onTap: () => bookmarks.toggle(_publication),
          ),
          _DetailActionButton(
            icon: const Icon(Icons.share),
            tooltip: 'Share',
            onTap: _sharePublication,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Title Card ─────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary.withAlpha(25),
                    colorScheme.primary.withAlpha(8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colorScheme.primary.withAlpha(40)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (_publication.year != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _publication.year.toString(),
                            style: TextStyle(
                              color: colorScheme.onPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      if (_publication.type != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _publication.type!,
                            style: TextStyle(
                              color: colorScheme.onSecondaryContainer,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _publication.title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Stats Row ──────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.format_quote,
                    label: 'Citations',
                    value: formatInt(_publication.citedByCount),
                    color: Colors.orange,
                    colorScheme: colorScheme,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.person_outline,
                    label: 'Authors',
                    value: _publication.authors.isEmpty
                        ? 'N/A'
                        : _publication.authors.length.toString(),
                    color: Colors.purple,
                    colorScheme: colorScheme,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.menu_book_outlined,
                    label: 'Journal',
                    value: _publication.journal.name,
                    color: Colors.teal,
                    colorScheme: colorScheme,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.label_outline,
                    label: 'Topics',
                    value: _publication.topics.isEmpty
                        ? 'N/A'
                        : _publication.topics.length.toString(),
                    color: Colors.blue,
                    colorScheme: colorScheme,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ── Citation Bar Chart ─────────────────────────────
            _CitationChart(
              citedByCount: _publication.citedByCount,
              year: _publication.year,
              colorScheme: colorScheme,
            ),

            const SizedBox(height: 24),

            // ── Authors Section ─────────────────────────────────
            if (_publication.authors.isNotEmpty) ...[
              _SectionHeader(
                icon: Icons.people_outline,
                title: 'Authors',
                colorScheme: colorScheme,
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _publication.authors.map((author) {
                    final name = author.displayName ?? author.name;
                    return Chip(
                      avatar: CircleAvatar(
                        backgroundColor: colorScheme.primary,
                        radius: 12,
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: TextStyle(
                            fontSize: 10,
                            color: colorScheme.onPrimary,
                          ),
                        ),
                      ),
                      label: Text(name, style: const TextStyle(fontSize: 13)),
                      backgroundColor: colorScheme.surfaceContainerHigh,
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // ── DOI Section ────────────────────────────────────
            if (_publication.doi != null && _publication.doi!.isNotEmpty) ...[
              _SectionHeader(
                icon: Icons.link,
                title: 'DOI',
                colorScheme: colorScheme,
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colorScheme.outline.withAlpha(50)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _publication.doi!,
                        style: TextStyle(
                          fontSize: 13,
                          color: colorScheme.primary,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Open DOI',
                      icon: Icon(
                        Icons.open_in_new,
                        color: colorScheme.primary,
                        size: 20,
                      ),
                      onPressed: () => _openDoi(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // ── Journal Info ───────────────────────────────────
            _SectionHeader(
              icon: Icons.library_books_outlined,
              title: 'Journal Information',
              colorScheme: colorScheme,
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _InfoRow(
                    label: 'Journal Name',
                    value: _publication.journal.name,
                    colorScheme: colorScheme,
                  ),
                  if (_publication.journal.publisher != null) ...[
                    const Divider(height: 20),
                    _InfoRow(
                      label: 'Publisher',
                      value: _publication.journal.publisher!,
                      colorScheme: colorScheme,
                    ),
                  ],
                  if (_publication.journal.issn != null) ...[
                    const Divider(height: 20),
                    _InfoRow(
                      label: 'ISSN',
                      value: _publication.journal.issn!,
                      colorScheme: colorScheme,
                    ),
                  ],
                  if (_publication.journal.country != null) ...[
                    const Divider(height: 20),
                    _InfoRow(
                      label: 'Country',
                      value: _publication.journal.country!,
                      colorScheme: colorScheme,
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Topics / Keywords ──────────────────────────────
            if (_publication.topics.isNotEmpty) ...[
              _SectionHeader(
                icon: Icons.label_outline,
                title: 'Topics & Keywords',
                colorScheme: colorScheme,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _publication.topics.map((topic) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      topic.displayName,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSecondaryContainer,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
            ],

            // ── Abstract ───────────────────────────────────────
            _SectionHeader(
              icon: Icons.article_outlined,
              title: 'Abstract',
              colorScheme: colorScheme,
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.outline.withAlpha(30)),
              ),
              child: _isLoadingFull
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Loading abstract...',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontStyle: FontStyle.italic,
                            color: colorScheme.onSurface.withAlpha(150),
                          ),
                        ),
                      ],
                    )
                  : SelectableText(
                      _publication.abstractText ??
                          'No abstract available for this publication.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.7,
                        fontStyle: _publication.abstractText == null
                            ? FontStyle.italic
                            : FontStyle.normal,
                        color: _publication.abstractText == null
                            ? colorScheme.onSurface.withAlpha(120)
                            : colorScheme.onSurface,
                      ),
                    ),
            ),

            const SizedBox(height: 32),

            // ── Open in Browser CTA ────────────────────────────
            if (_publication.doi != null && _publication.doi!.isNotEmpty)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _openDoi(context),
                  icon: const Icon(Icons.open_in_browser),
                  label: const Text('Read Full Paper'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _openOpenAlex(context),
                icon: const Icon(Icons.source_outlined),
                label: const Text('View on OpenAlex'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _openOpenAlex(BuildContext context) async {
    final id = _publication.id;
    final url = Uri.parse('https://openalex.org/works/$id');
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open OpenAlex')),
        );
      }
    }
  }
}

// ── Citation Chart Widget ──────────────────────────────────────

class _CitationChart extends StatelessWidget {
  const _CitationChart({
    required this.citedByCount,
    required this.year,
    required this.colorScheme,
  });

  final int citedByCount;
  final int? year;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final citationLevel = _getCitationLevel(citedByCount);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withAlpha(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics_outlined,
                size: 18,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Citation Strength',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              Text(
                '$citedByCount citation${citedByCount == 1 ? '' : 's'}',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurface.withAlpha(150),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (citedByCount == 0)
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: colorScheme.onSurface.withAlpha(120),
                ),
                const SizedBox(width: 8),
                Text(
                  'No citations recorded yet',
                  style: TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: colorScheme.onSurface.withAlpha(150),
                  ),
                ),
              ],
            )
          else ...[
            SizedBox(
              height: 80,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 5,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(show: false),
                  barGroups: [
                    _makeBarGroup(0, citationLevel >= 1, colorScheme),
                    _makeBarGroup(1, citationLevel >= 2, colorScheme),
                    _makeBarGroup(2, citationLevel >= 3, colorScheme),
                    _makeBarGroup(3, citationLevel >= 4, colorScheme),
                    _makeBarGroup(4, citationLevel >= 5, colorScheme),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              citationLevel == 5
                  ? '⭐⭐⭐⭐⭐ Extremely High Impact'
                  : citationLevel == 4
                  ? '⭐⭐⭐⭐ Very High Impact'
                  : citationLevel == 3
                  ? '⭐⭐⭐ High Impact'
                  : citationLevel == 2
                  ? '⭐⭐ Moderate Impact'
                  : '⭐ Low Impact',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _getImpactColor(citationLevel, colorScheme),
              ),
            ),
          ],
        ],
      ),
    );
  }

  int _getCitationLevel(int count) {
    if (count == 0) return 0;
    if (count < 10) return 1;
    if (count < 100) return 2;
    if (count < 1000) return 3;
    if (count < 10000) return 4;
    return 5;
  }

  Color _getImpactColor(int level, ColorScheme cs) {
    if (level == 0) return Colors.grey;
    if (level == 1) return Colors.green;
    if (level == 2) return Colors.teal;
    if (level == 3) return Colors.blue;
    if (level == 4) return Colors.orange;
    return Colors.red;
  }

  BarChartGroupData _makeBarGroup(int x, bool active, ColorScheme cs) {
    final colors = [
      Colors.green,
      Colors.teal,
      Colors.blue,
      Colors.orange,
      Colors.red,
    ];
    final color = active ? colors[x] : Colors.grey.shade300;
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: (x + 1).toDouble(),
          color: color,
          width: 20,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        ),
      ],
    );
  }
}

// ── Reusable Widgets ──────────────────────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.colorScheme,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: colorScheme.onSurface.withAlpha(160),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.colorScheme,
  });

  final IconData icon;
  final String title;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    required this.colorScheme,
  });

  final String label;
  final String value;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.onSurface.withAlpha(160),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontSize: 13, color: colorScheme.onSurface),
          ),
        ),
      ],
    );
  }
}

class _DetailActionButton extends StatelessWidget {
  const _DetailActionButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final Widget icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Tooltip(
        message: tooltip,
        child: Container(
          width: 38,
          height: 38,
          margin: const EdgeInsets.only(right: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: colorScheme.surfaceContainerHighest.withAlpha(150),
            border: Border.all(color: colorScheme.outline.withAlpha(30)),
          ),
          child: Center(child: icon),
        ),
      ),
    );
  }
}
