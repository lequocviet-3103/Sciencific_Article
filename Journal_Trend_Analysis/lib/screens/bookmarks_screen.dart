import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bookmark_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/empty_view.dart';
import '../widgets/modern_app_bar.dart';
import '../widgets/publication_card.dart';
import 'publication_detail_screen.dart';

class BookmarksScreen extends StatelessWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bookmarks = context.watch<BookmarkProvider>();
    final theme = context.watch<ThemeProvider>();
    final isDark = theme.isDark;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F1A) : const Color(0xFFF0F2F8),
      appBar: ModernAppBar(
        title: 'Saved Papers',
        subtitle: '${bookmarks.bookmarks.length} saved',
        actions: [
          if (bookmarks.hasBookmarks)
            _ModernIconButton(
              icon: Icons.delete_sweep,
              tooltip: 'Clear all',
              onTap: () => _confirmClear(context, bookmarks),
            ),
        ],
      ),
      body: bookmarks.hasBookmarks
          ? ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              itemCount: bookmarks.bookmarks.length,
              separatorBuilder: (context, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final pub = bookmarks.bookmarks[index];
                return Dismissible(
                  key: Key(pub.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 24),
                    decoration: BoxDecoration(
                      color: colorScheme.error,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(Icons.delete, color: colorScheme.onError),
                  ),
                  onDismissed: (_) => bookmarks.remove(pub.id),
                  child: PublicationCard(
                    publication: pub,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PublicationDetailScreen(publication: pub),
                      ),
                    ),
                  ),
                );
              },
            )
          : const EmptyView(
              message: 'No saved papers yet.\nTap the bookmark icon on any paper to save it here.',
              icon: Icons.bookmark_border,
            ),
    );
  }

  void _confirmClear(BuildContext context, BookmarkProvider bookmarks) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Bookmarks?'),
        content: const Text('This will remove all saved papers.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              bookmarks.clear();
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}

class _ModernIconButton extends StatelessWidget {
  const _ModernIconButton({
    required this.icon,
    required this.onTap,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Tooltip(
        message: tooltip ?? '',
        child: Container(
          width: 38,
          height: 38,
          margin: const EdgeInsets.only(right: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: colorScheme.surfaceContainerHighest.withAlpha(150),
            border: Border.all(
              color: colorScheme.outline.withAlpha(30),
            ),
          ),
          child: Center(
            child: Icon(icon, size: 20, color: colorScheme.onSurface),
          ),
        ),
      ),
    );
  }
}
