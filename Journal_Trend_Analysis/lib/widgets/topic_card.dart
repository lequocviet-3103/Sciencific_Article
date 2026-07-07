import 'package:flutter/material.dart';
import '../models/topic.dart';
import '../utils/number_format.dart';

class TopicCard extends StatelessWidget {
  const TopicCard({
    super.key,
    required this.topic,
    required this.onTap,
    this.compact = false,
  });

  final Topic topic;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (compact) {
      return _CompactTopicChip(topic: topic, onTap: onTap);
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: colorScheme.surface,
            border: Border.all(
              color: colorScheme.outline.withAlpha(25),
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withAlpha(8),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.primary.withAlpha(40),
                          colorScheme.secondary.withAlpha(40),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Icon(
                      _iconForTopic(topic),
                      color: colorScheme.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          topic.displayName,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (topic.subfield != null &&
                            topic.subfield != topic.displayName) ...[
                          const SizedBox(height: 2),
                          Text(
                            topic.subfield!,
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurface.withAlpha(140),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: colorScheme.onSurface.withAlpha(120),
                  ),
                ],
              ),
              if (topic.worksCount != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withAlpha(120),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.menu_book_rounded,
                        size: 12,
                        color: colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${formatCompact(topic.worksCount!)} works',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconForTopic(Topic t) {
    final name = t.displayName.toLowerCase();
    if (name.contains('artificial intelligence') ||
        name.contains('machine learning') ||
        name.contains('deep learning')) {
      return Icons.psychology_rounded;
    }
    if (name.contains('data')) return Icons.analytics_rounded;
    if (name.contains('security') || name.contains('cyber')) {
      return Icons.security_rounded;
    }
    if (name.contains('network') || name.contains('iot')) {
      return Icons.wifi_tethering_rounded;
    }
    if (name.contains('blockchain') || name.contains('crypto')) {
      return Icons.link_rounded;
    }
    if (name.contains('cloud')) return Icons.cloud_rounded;
    if (name.contains('software')) return Icons.code_rounded;
    if (name.contains('quantum')) return Icons.scatter_plot_rounded;
    if (name.contains('bio') || name.contains('genetic')) {
      return Icons.biotech_rounded;
    }
    if (name.contains('climate') || name.contains('environment')) {
      return Icons.eco_rounded;
    }
    if (name.contains('health') || name.contains('medic')) {
      return Icons.medical_services_rounded;
    }
    if (name.contains('physics')) return Icons.science_rounded;
    if (name.contains('chemistry')) return Icons.science_outlined;
    if (name.contains('math')) return Icons.calculate_rounded;
    if (name.contains('engineer')) return Icons.precision_manufacturing_rounded;
    if (name.contains('social') || name.contains('psychology')) {
      return Icons.psychology_alt_rounded;
    }
    return Icons.school_rounded;
  }
}

class _CompactTopicChip extends StatelessWidget {
  const _CompactTopicChip({required this.topic, required this.onTap});

  final Topic topic;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: colorScheme.surface,
            border: Border.all(
              color: colorScheme.outline.withAlpha(40),
            ),
          ),
          child: Text(
            topic.displayName,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
