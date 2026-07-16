import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/publication.dart';
import '../providers/theme_provider.dart';
import '../services/backend_paper_service.dart';
import '../widgets/publication_card.dart';
import '../widgets/loading_view.dart';
import '../widgets/error_view.dart';
import '../widgets/empty_view.dart';

class DatabasePapersScreen extends StatefulWidget {
  const DatabasePapersScreen({super.key});

  @override
  State<DatabasePapersScreen> createState() => _DatabasePapersScreenState();
}

class _DatabasePapersScreenState extends State<DatabasePapersScreen> {
  final BackendPaperService _service = BackendPaperService();
  final ScrollController _scrollController = ScrollController();

  List<Publication> _papers = [];
  bool _isLoading = false;
  bool _isSyncing = false;
  bool _hasMore = true;
  int _page = 1;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadPapers();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _service.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 300) {
      if (!_isLoading && _hasMore) _loadMore();
    }
  }

  Future<void> _loadPapers() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _error = null;
      _page = 1;
    });

    try {
      final result = await _service.searchPapers(page: 1);
      if (!mounted) return;
      setState(() {
        _papers = result.publications;
        _hasMore = result.hasMore;
        _page = 2;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final result = await _service.searchPapers(page: _page);
      if (!mounted) return;
      setState(() {
        _papers.addAll(result.publications);
        _hasMore = result.hasMore;
        _page++;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Load more failed: $e')),
      );
    }
  }

  Future<void> _syncFromOpenAlex() async {
    setState(() => _isSyncing = true);

    try {
      final result = await _service.triggerSync();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result)),
      );
      await _loadPapers();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sync failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    return Scaffold(
      backgroundColor:
          theme.isDark ? const Color(0xFF0F0F1A) : const Color(0xFFF0F2F8),
      appBar: AppBar(
        title: const Text('Database Papers'),
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            onPressed: _loadPapers,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
          IconButton(
            onPressed: _isSyncing ? null : _syncFromOpenAlex,
            icon: _isSyncing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.cloud_download),
            tooltip: 'Sync from OpenAlex',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _papers.isEmpty) {
      return const LoadingView(message: 'Loading papers...');
    }

    if (_error != null && _papers.isEmpty) {
      return ErrorView(message: _error!, onRetry: _loadPapers);
    }

    if (_papers.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const EmptyView(
              message: 'No papers yet.\nTap sync to fetch from OpenAlex.',
              icon: Icons.article_outlined,
            ),
            if (!_isSyncing)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: FilledButton.icon(
                  onPressed: _syncFromOpenAlex,
                  icon: const Icon(Icons.cloud_download),
                  label: const Text('Sync from OpenAlex'),
                ),
              ),
            if (_isSyncing)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                '${_papers.length} papers',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const Spacer(),
              if (_isSyncing)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              const SizedBox(width: 8),
              Text(
                _isSyncing ? 'Syncing...' : 'Sorted by citations',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadPapers,
            child: ListView.separated(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _papers.length + (_hasMore ? 1 : 0),
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                if (i >= _papers.length) return _buildLoadMore();
                final pub = _papers[i];
                return PublicationCard(
                  publication: pub,
                  onTap: () => _showDetail(pub),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadMore() {
    if (!_hasMore) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : TextButton(
                onPressed: _loadMore,
                child: const Text('Load more'),
              ),
      ),
    );
  }

  void _showDetail(Publication pub) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PaperDetailSheet(paper: pub),
    );
  }
}

class _PaperDetailSheet extends StatelessWidget {
  final Publication paper;

  const _PaperDetailSheet({required this.paper});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outline.withAlpha(60),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            paper.title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          if (paper.year != null)
            Text(
              '${paper.year}',
              style: TextStyle(
                  color: colorScheme.primary, fontWeight: FontWeight.w600),
            ),
          Text(
            paper.journal.displayName,
            style: TextStyle(color: colorScheme.outline)),
          if (paper.abstractText != null && paper.abstractText!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              paper.abstractText!,
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.format_quote, size: 16, color: colorScheme.outline),
              const SizedBox(width: 4),
              Text(
                '${paper.citedByCount} citations',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.outline,
                    ),
              ),
            ],
          ),
          if (paper.doi != null) ...[
            const SizedBox(height: 8),
            SelectableText(
              paper.doi!,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.primary,
                decoration: TextDecoration.underline,
              ),
            ),
          ],
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }
}
