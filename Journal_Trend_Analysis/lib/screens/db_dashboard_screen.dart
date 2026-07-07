import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import '../config/app_config.dart';
import '../utils/number_format.dart';
import '../widgets/modern_app_bar.dart';

/// A fully DB-backed dashboard — loads data directly from the backend without
/// requiring the user to run a search first.
class DbDashboardScreen extends StatefulWidget {
  const DbDashboardScreen({super.key});

  @override
  State<DbDashboardScreen> createState() => _DbDashboardScreenState();
}

class _DbDashboardScreenState extends State<DbDashboardScreen> {
  _DashData? _data;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() { _loading = true; _error = null; });
    try {
      final user = FirebaseAuth.instance.currentUser;
      final token = user != null ? await user.getIdToken() : null;
      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };
      final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/stats/dashboard');
      final response = await http.get(uri, headers: headers)
          .timeout(AppConfig.httpTimeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Server error ${response.statusCode}');
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (mounted) {
        setState(() {
          _data = _DashData.fromJson(json);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F1A) : const Color(0xFFF0F2F8),
      appBar: const ModernAppBar(title: 'Dashboard'),
      body: _buildBody(isDark, colorScheme),
    );
  }

  Widget _buildBody(bool isDark, ColorScheme cs) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null || _data == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined, size: 48, color: cs.onSurface.withAlpha(100)),
            const SizedBox(height: 12),
            Text('Could not load dashboard', style: TextStyle(color: cs.onSurface.withAlpha(160))),
            const SizedBox(height: 16),
            FilledButton.tonal(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }

    final d = _data!;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          _StatsGrid(data: d, cs: cs),
          const SizedBox(height: 16),
          if (d.papersByYear.isNotEmpty) ...[
            _SectionTitle(label: 'Publication Trend (${d.papersByYear.first.year}–${d.papersByYear.last.year})', cs: cs),
            const SizedBox(height: 8),
            _TrendChart(points: d.papersByYear, cs: cs, isDark: isDark),
            const SizedBox(height: 20),
          ],
          if (d.topJournals.isNotEmpty) ...[
            _SectionTitle(label: 'Top Journals by Paper Count', cs: cs),
            const SizedBox(height: 8),
            _TopJournalsList(journals: d.topJournals, cs: cs),
            const SizedBox(height: 20),
          ],
          if (d.topAuthors.isNotEmpty) ...[
            _SectionTitle(label: 'Top Authors by Paper Count', cs: cs),
            const SizedBox(height: 8),
            _TopAuthorsList(authors: d.topAuthors, cs: cs),
            const SizedBox(height: 20),
          ],
          if (d.mostCited != null) ...[
            _SectionTitle(label: 'Most Cited Paper', cs: cs),
            const SizedBox(height: 8),
            _MostCitedCard(paper: d.mostCited!, cs: cs),
          ],
        ],
      ),
    );
  }
}

// ── Stats grid ───────────────────────────────────────────────────────────────

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.data, required this.cs});
  final _DashData data;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: isDark
              ? [cs.primary.withAlpha(50), cs.secondary.withAlpha(35)]
              : [cs.primary.withAlpha(35), cs.secondary.withAlpha(25)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        border: Border.all(color: cs.primary.withAlpha(50)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _StatChip(label: 'Papers', value: formatCompact(data.paperCount), icon: Icons.article_outlined, color: cs.primary, cs: cs),
              const SizedBox(width: 10),
              _StatChip(label: 'Authors', value: formatCompact(data.authorCount), icon: Icons.people_outline, color: Colors.purple, cs: cs),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _StatChip(label: 'Journals', value: formatCompact(data.journalCount), icon: Icons.menu_book_outlined, color: Colors.teal, cs: cs),
              const SizedBox(width: 10),
              _StatChip(label: 'Avg Citations', value: data.avgCitations.toStringAsFixed(1), icon: Icons.format_quote, color: Colors.orange, cs: cs),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value, required this.icon, required this.color, required this.cs});
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: cs.surface.withAlpha(190),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withAlpha(40)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: cs.onSurface, height: 1.1)),
                  Text(label, style: TextStyle(fontSize: 11, color: cs.onSurface.withAlpha(140))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section title ─────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.label, required this.cs});
  final String label;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4, height: 18,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            gradient: LinearGradient(
              colors: [cs.primary, cs.secondary],
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: cs.onSurface, letterSpacing: -0.2)),
        ),
      ],
    );
  }
}

// ── Trend chart ───────────────────────────────────────────────────────────────

class _TrendChart extends StatelessWidget {
  const _TrendChart({required this.points, required this.cs, required this.isDark});
  final List<_YearCount> points;
  final ColorScheme cs;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return const SizedBox.shrink();

    final minYear = points.first.year;
    final maxCount = points.map((p) => p.count).reduce((a, b) => a > b ? a : b);
    final spots = points
        .map((p) => FlSpot((p.year - minYear).toDouble(), p.count.toDouble()))
        .toList();

    final yInterval = ((maxCount / 4).ceil()).clamp(1, maxCount).toDouble();

    return Container(
      height: 200,
      padding: const EdgeInsets.fromLTRB(8, 12, 16, 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline.withAlpha(25)),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            horizontalInterval: yInterval,
            getDrawingHorizontalLine: (_) => FlLine(color: cs.outline.withAlpha(30), strokeWidth: 1),
            drawVerticalLine: false,
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: yInterval,
                reservedSize: 40,
                getTitlesWidget: (v, _) => Text(
                  formatCompact(v.toInt()),
                  style: TextStyle(fontSize: 10, color: cs.onSurface.withAlpha(130)),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: points.length > 8 ? 3 : 1,
                getTitlesWidget: (v, _) {
                  final yr = minYear + v.toInt();
                  if ((yr - minYear) % (points.length > 8 ? 3 : 1) != 0) return const SizedBox.shrink();
                  return Text('$yr', style: TextStyle(fontSize: 10, color: cs.onSurface.withAlpha(130)));
                },
              ),
            ),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: cs.primary,
              barWidth: 2.5,
              dotData: FlDotData(
                show: points.length <= 10,
                getDotPainter: (_, _, _, _) => FlDotCirclePainter(
                  radius: 3.5, color: cs.primary,
                  strokeWidth: 1.5, strokeColor: cs.surface,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [cs.primary.withAlpha(80), cs.primary.withAlpha(0)],
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Top journals ──────────────────────────────────────────────────────────────

class _TopJournalsList extends StatelessWidget {
  const _TopJournalsList({required this.journals, required this.cs});
  final List<_NameCount> journals;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final maxCount = journals.map((j) => j.count).reduce((a, b) => a > b ? a : b);
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline.withAlpha(25)),
      ),
      child: Column(
        children: journals.asMap().entries.map((entry) {
          final i = entry.key;
          final j = entry.value;
          final fraction = j.count / maxCount;
          return Padding(
            padding: EdgeInsets.fromLTRB(16, i == 0 ? 14 : 10, 16, i == journals.length - 1 ? 14 : 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 22, height: 22,
                      decoration: BoxDecoration(color: cs.primary.withAlpha(20), borderRadius: BorderRadius.circular(6)),
                      child: Center(child: Text('${i + 1}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: cs.primary))),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(j.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: cs.onSurface), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    const SizedBox(width: 8),
                    Text('${j.count}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: cs.primary)),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: fraction,
                    backgroundColor: cs.primary.withAlpha(15),
                    color: cs.primary.withAlpha(160),
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Top authors ───────────────────────────────────────────────────────────────

class _TopAuthorsList extends StatelessWidget {
  const _TopAuthorsList({required this.authors, required this.cs});
  final List<_NameCount> authors;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline.withAlpha(25)),
      ),
      child: Column(
        children: authors.asMap().entries.map((entry) {
          final i = entry.key;
          final a = entry.value;
          return ListTile(
            dense: true,
            leading: CircleAvatar(
              radius: 16,
              backgroundColor: cs.primary.withAlpha(20),
              child: Text('${i + 1}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: cs.primary)),
            ),
            title: Text(a.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: cs.primary.withAlpha(15), borderRadius: BorderRadius.circular(8)),
              child: Text('${a.count} papers', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cs.primary)),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Most cited ────────────────────────────────────────────────────────────────

class _MostCitedCard extends StatelessWidget {
  const _MostCitedCard({required this.paper, required this.cs});
  final _MostCited paper;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline.withAlpha(25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(paper.title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface, height: 1.3)),
          if (paper.journalName != null) ...[
            const SizedBox(height: 6),
            Text(paper.journalName!, style: TextStyle(fontSize: 12, color: cs.onSurface.withAlpha(150)), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              if (paper.year != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(8)),
                  child: Text('${paper.year}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: cs.onPrimaryContainer)),
                ),
              const SizedBox(width: 8),
              Icon(Icons.format_quote, size: 14, color: cs.primary),
              const SizedBox(width: 4),
              Text(
                '${formatCompact(paper.citationCount ?? 0)} citations',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Data models ───────────────────────────────────────────────────────────────

class _DashData {
  final int paperCount;
  final int authorCount;
  final int journalCount;
  final int topicCount;
  final double avgCitations;
  final List<_NameCount> topJournals;
  final List<_NameCount> topAuthors;
  final List<_YearCount> papersByYear;
  final _MostCited? mostCited;

  const _DashData({
    required this.paperCount,
    required this.authorCount,
    required this.journalCount,
    required this.topicCount,
    required this.avgCitations,
    required this.topJournals,
    required this.topAuthors,
    required this.papersByYear,
    this.mostCited,
  });

  factory _DashData.fromJson(Map<String, dynamic> j) {
    return _DashData(
      paperCount: j['paperCount'] as int? ?? 0,
      authorCount: j['authorCount'] as int? ?? 0,
      journalCount: j['journalCount'] as int? ?? 0,
      topicCount: j['topicCount'] as int? ?? 0,
      avgCitations: (j['avgCitations'] as num?)?.toDouble() ?? 0,
      topJournals: (j['topJournals'] as List<dynamic>? ?? [])
          .map((e) => _NameCount.fromJson(e as Map<String, dynamic>))
          .toList(),
      topAuthors: (j['topAuthors'] as List<dynamic>? ?? [])
          .map((e) => _NameCount.fromJson(e as Map<String, dynamic>))
          .toList(),
      papersByYear: (j['papersByYear'] as List<dynamic>? ?? [])
          .map((e) => _YearCount.fromJson(e as Map<String, dynamic>))
          .toList(),
      mostCited: j['mostCited'] != null
          ? _MostCited.fromJson(j['mostCited'] as Map<String, dynamic>)
          : null,
    );
  }
}

class _NameCount {
  final String name;
  final int count;
  const _NameCount({required this.name, required this.count});
  factory _NameCount.fromJson(Map<String, dynamic> j) =>
      _NameCount(name: j['name']?.toString() ?? '', count: j['paperCount'] as int? ?? 0);
}

class _YearCount {
  final int year;
  final int count;
  const _YearCount({required this.year, required this.count});
  factory _YearCount.fromJson(Map<String, dynamic> j) =>
      _YearCount(year: j['year'] as int? ?? 0, count: j['count'] as int? ?? 0);
}

class _MostCited {
  final String title;
  final int? year;
  final int? citationCount;
  final String? journalName;
  const _MostCited({required this.title, this.year, this.citationCount, this.journalName});
  factory _MostCited.fromJson(Map<String, dynamic> j) => _MostCited(
        title: j['title']?.toString() ?? 'Unknown',
        year: j['publicationYear'] as int?,
        citationCount: j['citationCount'] as int?,
        journalName: j['journalName']?.toString(),
      );
}
