import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../services/analysis_service.dart';
import '../widgets/empty_view.dart';
import '../widgets/modern_app_bar.dart';

class CompareTrendScreen extends StatefulWidget {
  const CompareTrendScreen({super.key});

  @override
  State<CompareTrendScreen> createState() => _CompareTrendScreenState();
}

class _CompareTrendScreenState extends State<CompareTrendScreen> {
  final _service = AnalysisService();
  final _keywordController = TextEditingController();
  final List<String> _keywords = [];
  List<KeywordTrend>? _results;
  bool _loading = false;
  String? _error;

  static const _maxKeywords = 5;

  static const _seriesColors = [
    Color(0xFF6366F1),
    Color(0xFFEC4899),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFF3B82F6),
  ];

  @override
  void dispose() {
    _keywordController.dispose();
    _service.dispose();
    super.dispose();
  }

  void _addKeyword() {
    final kw = _keywordController.text.trim();
    if (kw.isEmpty) return;
    if (_keywords.contains(kw)) return;
    if (_keywords.length >= _maxKeywords) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Max 5 keywords allowed')),
      );
      return;
    }
    setState(() {
      _keywords.add(kw);
      _keywordController.clear();
      _results = null;
    });
  }

  void _removeKeyword(String kw) {
    setState(() {
      _keywords.remove(kw);
      _results = null;
    });
  }

  Future<void> _compare() async {
    if (_keywords.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
      _results = null;
    });

    try {
      final results = await _service.compareKeywords(_keywords);
      setState(() {
        _results = results;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: const ModernAppBar(title: 'Compare Trends'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Input area
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: colorScheme.surface,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Enter keywords to compare (max $_maxKeywords)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _keywordController,
                          onSubmitted: (_) => _addKeyword(),
                          decoration: const InputDecoration(
                            hintText: 'e.g. "AI", "Machine Learning"',
                            contentPadding:
                                EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                          textInputAction: TextInputAction.done,
                        ),
                      ),
                      const SizedBox(width: 10),
                      FilledButton(
                        onPressed: _addKeyword,
                        child: const Text('Add'),
                      ),
                    ],
                  ),
                  if (_keywords.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        for (var i = 0; i < _keywords.length; i++)
                          Chip(
                            label: Text(_keywords[i]),
                            labelStyle: TextStyle(
                              color: _seriesColors[i % _seriesColors.length],
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                            side: BorderSide(
                                color: _seriesColors[i % _seriesColors.length]
                                    .withAlpha(120)),
                            backgroundColor: _seriesColors[i % _seriesColors.length]
                                .withAlpha(20),
                            deleteIcon: Icon(
                              Icons.close,
                              size: 14,
                              color: _seriesColors[i % _seriesColors.length],
                            ),
                            onDeleted: () => _removeKeyword(_keywords[i]),
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _keywords.length < 2 ? null : _compare,
                      icon: const Icon(Icons.compare_arrows),
                      label: const Text('Compare'),
                    ),
                  ),
                  if (_keywords.length < 2)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Add at least 2 keywords to compare.',
                        style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.onSurface.withAlpha(120)),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Loading / error / results
            if (_loading)
              const Center(
                  child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ))
            else if (_error != null)
              Text(_error!,
                  style: TextStyle(color: colorScheme.error, fontSize: 13))
            else if (_results != null)
              _buildChart(_results!, colorScheme)
            else
              const EmptyView(
                icon: Icons.compare_arrows,
                message:
                    'Add keywords above and tap Compare to see side-by-side trends.',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(List<KeywordTrend> results, ColorScheme colorScheme) {
    // Collect all years across all series
    final allYears = results.expand((r) => r.trend.map((t) => t.year)).toSet().toList()
      ..sort();
    if (allYears.isEmpty) {
      return const EmptyView(message: 'No trend data available for these keywords.');
    }

    final maxCount = results
        .expand((r) => r.trend.map((t) => t.count))
        .fold<int>(1, (a, b) => a > b ? a : b);

    final bars = <LineChartBarData>[];
    for (var i = 0; i < results.length; i++) {
      final color = _seriesColors[i % _seriesColors.length];
      final trendMap = {for (final t in results[i].trend) t.year: t.count};
      bars.add(LineChartBarData(
        spots: [
          for (var j = 0; j < allYears.length; j++)
            FlSpot(j.toDouble(), (trendMap[allYears[j]] ?? 0).toDouble()),
        ],
        isCurved: true,
        barWidth: 2.5,
        color: color,
        dotData: FlDotData(show: allYears.length <= 15),
        belowBarData: BarAreaData(show: false),
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Legend
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            for (var i = 0; i < results.length; i++)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 20,
                    height: 3,
                    color: _seriesColors[i % _seriesColors.length],
                  ),
                  const SizedBox(width: 6),
                  Text(
                    results[i].keyword,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _seriesColors[i % _seriesColors.length],
                    ),
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: colorScheme.surface,
          ),
          height: 280,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) =>
                    FlLine(color: colorScheme.outline.withAlpha(25), strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 36,
                    getTitlesWidget: (v, _) => Text(
                      v.toInt().toString(),
                      style: TextStyle(
                          fontSize: 9, color: colorScheme.onSurface.withAlpha(100)),
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
                      if (i < 0 || i >= allYears.length) return const SizedBox();
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '${allYears[i]}',
                          style: TextStyle(
                              fontSize: 9,
                              color: colorScheme.onSurface.withAlpha(100)),
                        ),
                      );
                    },
                  ),
                ),
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              minY: 0,
              maxY: maxCount * 1.2,
              lineBarsData: bars,
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (spots) => spots.map((s) {
                    final i = s.x.toInt();
                    final year = i >= 0 && i < allYears.length ? allYears[i] : 0;
                    return LineTooltipItem(
                      '${results[s.barIndex].keyword}: ${s.y.toInt()} ($year)',
                      TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Data table
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: colorScheme.surface,
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Summary',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              for (var i = 0; i < results.length; i++) ...[
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _seriesColors[i % _seriesColors.length],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        results[i].keyword,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    Text(
                      '${results[i].trend.fold<int>(0, (s, t) => s + t.count)} total papers',
                      style: TextStyle(
                          fontSize: 12,
                          color: _seriesColors[i % _seriesColors.length],
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                if (i < results.length - 1)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Divider(
                        color: colorScheme.outline.withAlpha(25), height: 1),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
