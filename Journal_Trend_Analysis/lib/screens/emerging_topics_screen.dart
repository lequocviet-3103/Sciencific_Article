import 'package:flutter/material.dart';
import '../services/analysis_service.dart';
import '../widgets/empty_view.dart';
import '../widgets/error_view.dart';
import '../widgets/modern_app_bar.dart';
import 'topic_detail_screen.dart';

class EmergingTopicsScreen extends StatefulWidget {
  const EmergingTopicsScreen({super.key});

  @override
  State<EmergingTopicsScreen> createState() => _EmergingTopicsScreenState();
}

class _EmergingTopicsScreenState extends State<EmergingTopicsScreen> {
  final _service = AnalysisService();
  List<EmergingTopic>? _topics;
  bool _loading = true;
  String? _error;

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
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final topics = await _service.getEmergingTopics(take: 20);
      setState(() {
        _topics = topics;
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

    Widget body;
    if (_loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      body = ErrorView(message: _error!, onRetry: _load);
    } else if (_topics == null || _topics!.isEmpty) {
      body = const EmptyView(
        icon: Icons.trending_up,
        message: 'No emerging topics found.',
      );
    } else {
      body = RefreshIndicator(
        onRefresh: _load,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _topics!.length,
          itemBuilder: (context, i) => _EmergingTopicCard(
            topic: _topics![i],
            rank: i + 1,
            colorScheme: colorScheme,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: const ModernAppBar(title: 'Emerging Topics'),
      body: body,
    );
  }
}

class _EmergingTopicCard extends StatelessWidget {
  const _EmergingTopicCard({
    required this.topic,
    required this.rank,
    required this.colorScheme,
  });

  final EmergingTopic topic;
  final int rank;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final growthPct = (topic.growthRatio * 100).toStringAsFixed(0);
    final isHot = topic.growthRatio >= 0.7;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TopicDetailScreen(
            topicId: topic.topicId,
            topicName: topic.name,
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: colorScheme.surface,
          border: Border.all(
            color: isHot
                ? colorScheme.primary.withAlpha(80)
                : colorScheme.outline.withAlpha(20),
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withAlpha(6),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rank badge
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: rank <= 3
                      ? [colorScheme.primary, colorScheme.secondary]
                      : [
                          colorScheme.primaryContainer,
                          colorScheme.secondaryContainer,
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                '$rank',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: rank <= 3 ? Colors.white : colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          topic.name,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                      if (isHot)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.orange.withAlpha(30),
                          ),
                          child: const Text(
                            '🔥 Hot',
                            style: TextStyle(
                                fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                  if (topic.field != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      topic.field!,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _StatChip(
                        icon: Icons.article_outlined,
                        label: '${topic.recentCount} recent',
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      _StatChip(
                        icon: Icons.trending_up,
                        label: '$growthPct% recent',
                        color: Colors.green.shade600,
                      ),
                      const SizedBox(width: 8),
                      _StatChip(
                        icon: Icons.library_books,
                        label: '${topic.totalCount} total',
                        color: colorScheme.onSurface.withAlpha(140),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                color: colorScheme.onSurface.withAlpha(80), size: 20),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 3),
        Text(label,
            style: TextStyle(
                fontSize: 11, color: color, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
