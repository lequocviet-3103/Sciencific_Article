import 'package:flutter/material.dart';
import '../models/topic.dart';
import '../utils/number_format.dart';

/// Lightweight overview shown at the top of TopicsScreen. Shows total
/// topics, total works across the catalog, and the top fields by
/// aggregated work count. All numbers are computed locally from the
/// featured topics payload (which already includes `works_count` per
/// topic), so no extra API call is needed.
class TopicsOverview extends StatelessWidget {
  const TopicsOverview({super.key, required this.topics});

  final List<Topic> topics;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (topics.isEmpty) {
      return const SizedBox.shrink();
    }

    // ── Aggregations ──
    final totalTopics = topics.length;
    final totalWorks = topics.fold<int>(
      0,
      (s, t) => s + (t.worksCount ?? 0),
    );

    // Aggregate by field, then by domain, so the breakdown reflects the
    // same hierarchy OpenAlex uses.
    final byField = <String, int>{};
    final byDomain = <String, int>{};
    for (final t in topics) {
      final w = t.worksCount ?? 0;
      if (t.field != null && t.field!.isNotEmpty) {
        byField[t.field!] = (byField[t.field!] ?? 0) + w;
      }
      if (t.domain != null && t.domain!.isNotEmpty) {
        byDomain[t.domain!] = (byDomain[t.domain!] ?? 0) + w;
      }
    }

    final topFields = (byField.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)))
        .take(4)
        .toList();
    final topDomains = (byDomain.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)))
        .take(3)
        .toList();

    final maxFieldValue =
        topFields.isEmpty ? 0.0 : topFields.first.value.toDouble();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: isDark
              ? [
                  colorScheme.primary.withAlpha(45),
                  colorScheme.secondary.withAlpha(35),
                  colorScheme.tertiary.withAlpha(25),
                ]
              : [
                  colorScheme.primary.withAlpha(35),
                  colorScheme.secondary.withAlpha(28),
                  colorScheme.tertiary.withAlpha(20),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: colorScheme.primary.withAlpha(50),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withAlpha(15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: colorScheme.surface.withAlpha(200),
                ),
                child: Icon(
                  Icons.dashboard_rounded,
                  color: colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Overview',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Research Database',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Curated topics and their field distribution',
            style: TextStyle(
              fontSize: 11,
              color: colorScheme.onSurface.withAlpha(160),
            ),
          ),

          const SizedBox(height: 16),

          // ── KPI row ──
          Row(
            children: [
              Expanded(
                child: _KpiTile(
                  label: 'Topics',
                  value: formatCompact(totalTopics),
                  icon: Icons.topic_rounded,
                  color: colorScheme.primary,
                  colorScheme: colorScheme,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _KpiTile(
                  label: 'Total Works',
                  value: formatCompact(totalWorks),
                  icon: Icons.menu_book_rounded,
                  color: colorScheme.secondary,
                  colorScheme: colorScheme,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _KpiTile(
                  label: 'Fields',
                  value: formatCompact(byField.length),
                  icon: Icons.category_rounded,
                  color: colorScheme.tertiary,
                  colorScheme: colorScheme,
                ),
              ),
            ],
          ),

          if (topFields.isNotEmpty) ...[
            const SizedBox(height: 18),
            Row(
              children: [
                Icon(
                  Icons.bar_chart_rounded,
                  size: 14,
                  color: colorScheme.onSurface.withAlpha(160),
                ),
                const SizedBox(width: 6),
                Text(
                  'Top Fields by Works',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface.withAlpha(180),
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            for (var i = 0; i < topFields.length; i++)
              _FieldProgressRow(
                label: topFields[i].key,
                value: topFields[i].value,
                maxValue: maxFieldValue,
                colorIndex: i,
                colorScheme: colorScheme,
              ),
          ],

          if (topDomains.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: topDomains
                  .map(
                    (e) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surface.withAlpha(180),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: colorScheme.outline.withAlpha(30),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.public_rounded,
                            size: 11,
                            color: colorScheme.onSurface.withAlpha(150),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            e.key,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withAlpha(35),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              formatCompact(e.value),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _KpiTile extends StatelessWidget {
  const _KpiTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.colorScheme,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface.withAlpha(190),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withAlpha(40),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
              height: 1.1,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface.withAlpha(150),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _FieldProgressRow extends StatelessWidget {
  const _FieldProgressRow({
    required this.label,
    required this.value,
    required this.maxValue,
    required this.colorIndex,
    required this.colorScheme,
  });

  final String label;
  final int value;
  final double maxValue;
  final int colorIndex;
  final ColorScheme colorScheme;

  static const _palette = <Color>[
    Color(0xFF6366F1),
    Color(0xFF8B5CF6),
    Color(0xFF06B6D4),
    Color(0xFFF59E0B),
    Color(0xFF10B981),
    Color(0xFFEC4899),
  ];

  @override
  Widget build(BuildContext context) {
    final ratio = maxValue == 0 ? 0.0 : value / maxValue;
    final color = _palette[colorIndex % _palette.length];

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                formatCompact(value),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: Stack(
              children: [
                Container(
                  height: 5,
                  color: colorScheme.surface.withAlpha(120),
                ),
                FractionallySizedBox(
                  widthFactor: ratio.clamp(0.0, 1.0),
                  child: Container(
                    height: 5,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color.withAlpha(220), color],
                      ),
                    ),
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
