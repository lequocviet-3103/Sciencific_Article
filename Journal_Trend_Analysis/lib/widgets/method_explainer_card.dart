import 'package:flutter/material.dart';
import '../models/author_count.dart';
import '../utils/number_format.dart';

/// "How was this number computed?" expandable card. Drops onto the
/// dashboard / trend screens so the math behind every KPI is
/// reproducible — useful for presentations and for answering a
/// reviewer's "but how did you get that?" question.
class MethodExplainerCard extends StatefulWidget {
  const MethodExplainerCard({
    super.key,
    required this.loadedCount,
    required this.apiTotalCount,
    required this.uniqueAuthors,
    required this.totalAuthorships,
    required this.distinctFields,
    required this.totalTopics,
    required this.query,
  });

  final int loadedCount;
  final int apiTotalCount;
  final int uniqueAuthors;
  final int totalAuthorships;
  final int distinctFields;
  final int totalTopics;
  final String query;

  @override
  State<MethodExplainerCard> createState() => _MethodExplainerCardState();
}

class _MethodExplainerCardState extends State<MethodExplainerCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final capped =
        widget.apiTotalCount > 0 && widget.apiTotalCount > widget.loadedCount;
    final samplePercent = widget.apiTotalCount > 0
        ? ((widget.loadedCount / widget.apiTotalCount) * 100)
            .clamp(0, 100)
            .toStringAsFixed(1)
        : '100.0';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: colorScheme.surfaceContainerHighest.withAlpha(80),
        border: Border.all(
          color: colorScheme.outline.withAlpha(40),
        ),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Icon(
                    Icons.calculate_outlined,
                    size: 18,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'How were these numbers computed?',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: colorScheme.onSurface.withAlpha(160),
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _row(
                    context,
                    'Sample size',
                    '${formatInt(widget.loadedCount)} publications'
                    '${widget.apiTotalCount > 0 ? ' ($samplePercent% of ${formatInt(widget.apiTotalCount)} matches)' : ''}',
                    capped
                        ? 'OpenAlex allows deep pagination but the app caps at the first ${formatInt(widget.loadedCount)} records to keep memory bounded.'
                        : 'All matches were loaded.',
                  ),
                  _row(
                    context,
                    'Unique authors',
                    formatInt(widget.uniqueAuthors),
                    'Distinct author names (case-insensitive, trimmed). "J. Smith" and "John Smith" are merged into one.',
                  ),
                  _row(
                    context,
                    'Author appearances',
                    formatInt(widget.totalAuthorships),
                    'Sum of (authors per paper) across the sample. Always ≥ unique authors; a paper with 3 authors contributes 3.',
                  ),
                  _row(
                    context,
                    'Fields shown',
                    '${widget.distinctFields} field${widget.distinctFields == 1 ? '' : 's'}',
                    'Each paper counted once under the field of its highest-scored topic (the "primary" topic).',
                  ),
                  _row(
                    context,
                    'Avg citations',
                    'Σ(cited_by_count) ÷ N',
                    'Total citation count across the sample, divided by the number of publications in the sample.',
                  ),
                  _row(
                    context,
                    'Top journal / year',
                    'argmax over the sample',
                    'The journal / year with the highest publication count within the loaded sample.',
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: colorScheme.primary.withAlpha(20),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 14,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            widget.query.isEmpty
                                ? 'All numbers above are computed locally from the publications currently loaded. Source: OpenAlex API.'
                                : 'Query used: "${widget.query}". All numbers above are computed locally from the publications currently loaded. Source: OpenAlex API.',
                            style: TextStyle(
                              fontSize: 11,
                              color: colorScheme.onSurface.withAlpha(180),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _row(
    BuildContext context,
    String label,
    String formula,
    String detail,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface.withAlpha(180),
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formula,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurface.withAlpha(160),
                    height: 1.35,
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

/// Authors panel with expandable evidence: tap an author to see the
/// papers they appear in, so a reviewer can verify the count manually.
class AuthorsEvidenceCard extends StatefulWidget {
  const AuthorsEvidenceCard({
    super.key,
    required this.authors,
    required this.onSampleTap,
  });

  final List<AuthorCount> authors;
  final void Function(String publicationId) onSampleTap;

  @override
  State<AuthorsEvidenceCard> createState() => _AuthorsEvidenceCardState();
}

class _AuthorsEvidenceCardState extends State<AuthorsEvidenceCard> {
  int? _expandedIndex;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (widget.authors.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: colorScheme.surface,
        border: Border.all(
          color: colorScheme.outline.withAlpha(20),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withAlpha(8),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.tertiary.withAlpha(40),
                      colorScheme.primary.withAlpha(40),
                    ],
                  ),
                ),
                child: Icon(
                  Icons.people_alt_rounded,
                  color: colorScheme.tertiary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Top Authors',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              Text(
                'Tap to verify',
                style: TextStyle(
                  fontSize: 10,
                  fontStyle: FontStyle.italic,
                  color: colorScheme.onSurface.withAlpha(140),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Each card shows the papers that author appears on',
            style: TextStyle(
              fontSize: 11,
              color: colorScheme.onSurface.withAlpha(150),
            ),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < widget.authors.length; i++)
            _AuthorRow(
              author: widget.authors[i],
              expanded: _expandedIndex == i,
              onTap: () => setState(() {
                _expandedIndex = _expandedIndex == i ? null : i;
              }),
              onSampleTap: widget.onSampleTap,
            ),
        ],
      ),
    );
  }
}

class _AuthorRow extends StatelessWidget {
  const _AuthorRow({
    required this.author,
    required this.expanded,
    required this.onTap,
    required this.onSampleTap,
  });

  final AuthorCount author;
  final bool expanded;
  final VoidCallback onTap;
  final void Function(String publicationId) onSampleTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: expanded
            ? colorScheme.primary.withAlpha(20)
            : colorScheme.surfaceContainerHighest.withAlpha(80),
        border: Border.all(
          color: expanded
              ? colorScheme.primary.withAlpha(80)
              : colorScheme.outline.withAlpha(20),
        ),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.tertiary.withAlpha(180),
                          colorScheme.primary.withAlpha(180),
                        ],
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      author.name.isEmpty
                          ? '?'
                          : author.name[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          author.name,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'appears in ${formatInt(author.count)} paper${author.count == 1 ? '' : 's'}',
                          style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.onSurface.withAlpha(160),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      formatInt(author.count),
                      style: TextStyle(
                        color: colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: colorScheme.onSurface.withAlpha(160),
                  ),
                ],
              ),
            ),
          ),
          if (expanded && author.sampleTitles.isNotEmpty) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sample of papers (${author.sampleTitles.length} of ${author.count}):',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.4,
                      color: colorScheme.onSurface.withAlpha(160),
                    ),
                  ),
                  const SizedBox(height: 6),
                  for (final title in author.sampleTitles)
                    InkWell(
                      borderRadius: BorderRadius.circular(6),
                      onTap: author.firstPublicationId == null
                          ? null
                          : () => onSampleTap(author.firstPublicationId!),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Icon(
                                Icons.article_outlined,
                                size: 12,
                                color: colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                title,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.onSurface,
                                  height: 1.3,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
