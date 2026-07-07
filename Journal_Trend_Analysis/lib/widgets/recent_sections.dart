import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/publication.dart';
import '../models/topic.dart';
import '../providers/recent_provider.dart';
import '../screens/publication_detail_screen.dart';
import '../screens/search_screen.dart';
import '../utils/number_format.dart';

/// Renders two horizontal "chips" rows: recently selected topics and
/// recently opened publications. Hidden when the user has no history
/// yet. Designed to sit just below the overview dashboard on the home
/// screen.
class RecentSections extends StatelessWidget {
  const RecentSections({super.key});

  @override
  Widget build(BuildContext context) {
    final recents = context.watch<RecentProvider>();
    if (recents.publications.isEmpty && recents.topics.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (recents.topics.isNotEmpty)
          _RecentTopicsRow(topics: recents.topics),
        if (recents.topics.isNotEmpty && recents.publications.isNotEmpty)
          const SizedBox(height: 18),
        if (recents.publications.isNotEmpty)
          _RecentPublicationsRow(publications: recents.publications),
      ],
    );
  }
}

// ── Section header ─────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.count,
    required this.onClear,
  });

  final IconData icon;
  final String title;
  final int count;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 0, 2, 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: colorScheme.primary.withAlpha(25),
            ),
            child: Icon(
              icon,
              color: colorScheme.primary,
              size: 14,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '· $count',
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurface.withAlpha(140),
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          if (count > 0)
            TextButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.delete_sweep_rounded, size: 14),
              label: const Text('Clear'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                foregroundColor: colorScheme.onSurface.withAlpha(160),
                textStyle: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Recent topics ──────────────────────────────────────────────
class _RecentTopicsRow extends StatelessWidget {
  const _RecentTopicsRow({required this.topics});

  final List<Topic> topics;

  Future<void> _openSearch(BuildContext context, Topic topic) async {
    // Re-track so the topic floats back to the front when re-tapped.
    context.read<RecentProvider>().trackTopic(topic);
    await Navigator.push(
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
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          icon: Icons.history_rounded,
          title: 'Recent Topics',
          count: topics.length,
          onClear: () => context.read<RecentProvider>().clearTopics(),
        ),
        SizedBox(
          height: 76,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.zero,
            itemCount: topics.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (ctx, i) {
              final t = topics[i];
              return _RecentTopicChip(
                topic: t,
                onTap: () => _openSearch(context, t),
              );
            },
          ),
        ),
        const SizedBox(height: 4),
        // Hint line
        Row(
          children: [
            Icon(
              Icons.info_outline_rounded,
              size: 11,
              color: colorScheme.onSurface.withAlpha(120),
            ),
            const SizedBox(width: 4),
            Text(
              'Tap a topic to re-run the search',
              style: TextStyle(
                fontSize: 10,
                color: colorScheme.onSurface.withAlpha(120),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RecentTopicChip extends StatelessWidget {
  const _RecentTopicChip({required this.topic, required this.onTap});

  final Topic topic;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        width: 180,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: colorScheme.surface,
          border: Border.all(
            color: colorScheme.primary.withAlpha(40),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary,
                    colorScheme.secondary,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                topic.displayName.isEmpty
                    ? '?'
                    : topic.displayName[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    topic.displayName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (topic.field != null && topic.field!.isNotEmpty)
                    Text(
                      topic.field!,
                      style: TextStyle(
                        fontSize: 10,
                        color: colorScheme.onSurface.withAlpha(140),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            Icon(
              Icons.north_east_rounded,
              size: 14,
              color: colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Recent publications ────────────────────────────────────────
class _RecentPublicationsRow extends StatelessWidget {
  const _RecentPublicationsRow({required this.publications});

  final List<Publication> publications;

  void _openDetail(BuildContext context, Publication pub) {
    context.read<RecentProvider>().trackPublication(pub);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PublicationDetailScreen(publication: pub),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          icon: Icons.visibility_outlined,
          title: 'Recent Publications',
          count: publications.length,
          onClear: () => context.read<RecentProvider>().clearPublications(),
        ),
        SizedBox(
          height: 130,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.zero,
            itemCount: publications.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (ctx, i) {
              final p = publications[i];
              return _RecentPublicationCard(
                publication: p,
                onTap: () => _openDetail(context, p),
              );
            },
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(
              Icons.info_outline_rounded,
              size: 11,
              color: colorScheme.onSurface.withAlpha(120),
            ),
            const SizedBox(width: 4),
            Text(
              'Tap a paper to re-open it',
              style: TextStyle(
                fontSize: 10,
                color: colorScheme.onSurface.withAlpha(120),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RecentPublicationCard extends StatelessWidget {
  const _RecentPublicationCard({
    required this.publication,
    required this.onTap,
  });

  final Publication publication;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final p = publication;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: colorScheme.surface,
          border: Border.all(
            color: colorScheme.outline.withAlpha(20),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    (p.year ?? 'N/A').toString(),
                    style: TextStyle(
                      color: colorScheme.onPrimary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.format_quote_rounded,
                  size: 12,
                  color: colorScheme.onSurface.withAlpha(150),
                ),
                const SizedBox(width: 2),
                Text(
                  formatCompact(p.citedByCount),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface.withAlpha(180),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Text(
                p.title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                  height: 1.3,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              p.journal.name.isEmpty
                  ? 'Unknown journal'
                  : p.journal.name,
              style: TextStyle(
                fontSize: 10,
                color: colorScheme.onSurface.withAlpha(150),
                fontStyle: p.journal.name.isEmpty
                    ? FontStyle.italic
                    : FontStyle.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
