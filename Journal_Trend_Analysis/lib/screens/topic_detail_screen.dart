import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import '../config/app_config.dart';
import '../models/publication.dart';
import '../services/analysis_service.dart';
import '../widgets/empty_view.dart';
import '../widgets/modern_app_bar.dart';
import 'publication_detail_screen.dart';

class TopicDetailScreen extends StatefulWidget {
  const TopicDetailScreen({
    super.key,
    required this.topicId,
    this.topicName,
  });

  final String topicId;
  final String? topicName;

  @override
  State<TopicDetailScreen> createState() => _TopicDetailScreenState();
}

class _TopicDetailScreenState extends State<TopicDetailScreen> {
  final _service = AnalysisService();
  Map<String, dynamic>? _topic;
  final List<Publication> _papers = [];
  bool _loading = true;
  bool _loadingPapers = false;
  String? _error;
  int _page = 1;
  int _total = 0;
  bool _hasMore = true;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _load();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _service.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_loadingPapers && _hasMore) _loadMorePapers();
    }
  }

  Future<void> _load() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final idToken = user != null ? await user.getIdToken() : null;
      final headers = {
        'Accept': 'application/json',
        if (idToken != null) 'Authorization': 'Bearer $idToken',
      };

      final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/topics/${widget.topicId}');
      final response = await http.get(uri, headers: headers).timeout(AppConfig.httpTimeout);

      if (response.statusCode == 200) {
        setState(() {
          _topic = jsonDecode(response.body) as Map<String, dynamic>;
          _loading = false;
        });
        await _loadMorePapers();
      } else {
        setState(() {
          _error = 'Failed to load topic (${response.statusCode})';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _loadMorePapers() async {
    if (_loadingPapers) return;
    setState(() => _loadingPapers = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final idToken = user != null ? await user.getIdToken() : null;
      final headers = {
        'Accept': 'application/json',
        if (idToken != null) 'Authorization': 'Bearer $idToken',
      };

      final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/papers').replace(
        queryParameters: {
          'topicId': widget.topicId,
          'page': _page.toString(),
          'pageSize': '20',
          'sort': 'cited_by_count:desc',
        },
      );
      final response =
          await http.get(uri, headers: headers).timeout(AppConfig.httpTimeout);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final items = (body['items'] as List? ?? [])
            .map((e) => Publication.fromBackendJson(e as Map<String, dynamic>))
            .toList();
        final total = body['total'] as int? ?? 0;
        final pageCount = body['pageCount'] as int? ?? 1;

        setState(() {
          _papers.addAll(items);
          _total = total;
          _hasMore = _page < pageCount;
          _page++;
        });
      }
    } catch (_) {
    } finally {
      setState(() => _loadingPapers = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final topicName = _topic?['name']?.toString() ?? widget.topicName ?? 'Topic';

    if (_loading) {
      return Scaffold(
        appBar: ModernAppBar(title: topicName),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: ModernAppBar(title: topicName),
        body: Center(child: Text(_error!, style: TextStyle(color: colorScheme.error))),
      );
    }

    final trendByYear = (_topic?['trendByYear'] as List? ?? [])
        .map((e) => TrendPoint(
              year: (e as Map)['year'] as int,
              count: e['count'] as int,
            ))
        .toList();

    return Scaffold(
      appBar: ModernAppBar(title: topicName),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Info card
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primaryContainer,
                    colorScheme.tertiaryContainer,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    topicName,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (_topic?['field'] != null)
                    _Chip(label: _topic!['field'].toString(), colorScheme: colorScheme),
                  if (_topic?['domain'] != null)
                    _Chip(label: _topic!['domain'].toString(), colorScheme: colorScheme),
                  const SizedBox(height: 10),
                  Text(
                    '$_total paper${_total == 1 ? '' : 's'} in database',
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onPrimaryContainer.withAlpha(180),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Trend chart
          if (trendByYear.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: colorScheme.surface,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Publications per Year',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 180,
                        child: LineChart(
                          _buildLineChart(trendByYear, colorScheme),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Text(
                'Top Papers',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          ),

          if (_papers.isEmpty && !_loadingPapers)
            const SliverFillRemaining(
              child: EmptyView(message: 'No papers found for this topic.'),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index >= _papers.length) {
                    return _loadingPapers
                        ? const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        : const SizedBox.shrink();
                  }
                  final p = _papers[index];
                  return _TopicPaperTile(paper: p);
                },
                childCount: _papers.length + (_loadingPapers || _hasMore ? 1 : 0),
              ),
            ),
        ],
      ),
    );
  }

  LineChartData _buildLineChart(List<TrendPoint> points, ColorScheme cs) {
    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (_) =>
            FlLine(color: cs.outline.withAlpha(25), strokeWidth: 1),
      ),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 32,
            getTitlesWidget: (v, _) => Text(
              v.toInt().toString(),
              style: TextStyle(fontSize: 9, color: cs.onSurface.withAlpha(100)),
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 28,
            interval: 1,
            getTitlesWidget: (v, _) {
              final i = v.toInt();
              if (i < 0 || i >= points.length) return const SizedBox();
              return Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${points[i].year}',
                  style: TextStyle(fontSize: 9, color: cs.onSurface.withAlpha(100)),
                ),
              );
            },
          ),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: [
            for (var i = 0; i < points.length; i++)
              FlSpot(i.toDouble(), points[i].count.toDouble()),
          ],
          isCurved: true,
          barWidth: 3,
          color: cs.primary,
          dotData: FlDotData(show: points.length <= 15),
          belowBarData: BarAreaData(
            show: true,
            color: cs.primary.withAlpha(40),
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.colorScheme});
  final String label;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: colorScheme.primary.withAlpha(30),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _TopicPaperTile extends StatelessWidget {
  const _TopicPaperTile({required this.paper});
  final Publication paper;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PublicationDetailScreen(publication: paper)),
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: colorScheme.surface,
          border: Border.all(color: colorScheme.outline.withAlpha(20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              paper.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                if (paper.year != null) ...[
                  Icon(Icons.calendar_today,
                      size: 12, color: colorScheme.onSurface.withAlpha(120)),
                  const SizedBox(width: 4),
                  Text('${paper.year}',
                      style: TextStyle(
                          fontSize: 12, color: colorScheme.onSurface.withAlpha(150))),
                  const SizedBox(width: 12),
                ],
                Icon(Icons.format_quote,
                    size: 12, color: colorScheme.primary.withAlpha(180)),
                const SizedBox(width: 4),
                Text('${paper.citedByCount} citations',
                    style: TextStyle(fontSize: 12, color: colorScheme.primary)),
                const Spacer(),
                Icon(Icons.chevron_right,
                    size: 16, color: colorScheme.onSurface.withAlpha(80)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
