import 'package:flutter/material.dart';
import '../utils/number_format.dart';

class FieldBreakdownCard extends StatelessWidget {
  const FieldBreakdownCard({
    super.key,
    required this.fieldCounts,
    this.maxItems = 6,
  });

  /// Map of field name → publication count. Already aggregated by the
  /// analytics service.
  final Map<String, int> fieldCounts;
  final int maxItems;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (fieldCounts.isEmpty) {
      return _emptyState(colorScheme);
    }

    final entries = fieldCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final shown = entries.take(maxItems).toList();
    final totalShown = shown.fold<int>(0, (s, e) => s + e.value);
    final maxValue = shown.first.value;
    final palette = _palette(colorScheme, isDark);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: colorScheme.surface,
        border: Border.all(color: colorScheme.outline.withAlpha(20)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withAlpha(10),
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
                      colorScheme.primary.withAlpha(40),
                      colorScheme.secondary.withAlpha(40),
                    ],
                  ),
                ),
                child: Icon(
                  Icons.category_rounded,
                  color: colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Overview by Field',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              Text(
                '${shown.length} fields · ${formatInt(totalShown)} papers',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface.withAlpha(120),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Each paper counted under its primary topic field',
            style: TextStyle(
              fontSize: 11,
              color: colorScheme.onSurface.withAlpha(130),
            ),
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < shown.length; i++)
            _FieldRow(
              label: shown[i].key,
              count: shown[i].value,
              maxValue: maxValue,
              color: palette[i % palette.length],
            ),
          if (entries.length > maxItems) ...[
            const SizedBox(height: 10),
            Text(
              '+ ${entries.length - maxItems} more field${entries.length - maxItems == 1 ? '' : 's'} not shown',
              style: TextStyle(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: colorScheme.onSurface.withAlpha(120),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _emptyState(ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: colorScheme.surface,
        border: Border.all(color: colorScheme.outline.withAlpha(20)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.category_outlined,
            color: colorScheme.onSurface.withAlpha(120),
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'No field information available for the current results.',
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurface.withAlpha(160),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Color> _palette(ColorScheme scheme, bool isDark) {
    // Hand-picked gradient-friendly palette that works on both light
    // and dark surfaces.
    return <Color>[
      scheme.primary,
      scheme.secondary,
      scheme.tertiary,
      const Color(0xFF8B5CF6),
      const Color(0xFF06B6D4),
      const Color(0xFFF59E0B),
      const Color(0xFF10B981),
      const Color(0xFFEC4899),
    ];
  }
}

class _FieldRow extends StatelessWidget {
  const _FieldRow({
    required this.label,
    required this.count,
    required this.maxValue,
    required this.color,
  });

  final String label;
  final int count;
  final int maxValue;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final ratio = maxValue == 0 ? 0.0 : count / maxValue;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                formatInt(count),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'papers',
                style: TextStyle(
                  fontSize: 11,
                  color: colorScheme.onSurface.withAlpha(140),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Stack(
              children: [
                Container(
                  height: 6,
                  color: colorScheme.surfaceContainerHighest.withAlpha(120),
                ),
                FractionallySizedBox(
                  widthFactor: ratio.clamp(0.0, 1.0),
                  child: Container(
                    height: 6,
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
