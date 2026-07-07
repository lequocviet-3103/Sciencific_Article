import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import '../config/app_config.dart';
import '../models/publication.dart';
import '../services/analysis_service.dart';
import '../widgets/empty_view.dart';
import '../widgets/modern_app_bar.dart';
import 'publication_detail_screen.dart';

class AuthorDetailScreen extends StatefulWidget {
  const AuthorDetailScreen({
    super.key,
    required this.authorId,
    this.authorName,
  });

  final String authorId;
  final String? authorName;

  @override
  State<AuthorDetailScreen> createState() => _AuthorDetailScreenState();
}

class _AuthorDetailScreenState extends State<AuthorDetailScreen> {
  final _service = AnalysisService();
  AuthorInfo? _author;
  List<Publication> _papers = [];
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
      final author = await _service.getAuthorById(widget.authorId);
      setState(() {
        _author = author;
        _loading = false;
      });
      await _loadMorePapers();
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

      final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/authors/${widget.authorId}/papers')
          .replace(queryParameters: {'page': _page.toString(), 'pageSize': '20'});
      final response = await http.get(uri, headers: headers)
          .timeout(AppConfig.httpTimeout);

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
    final displayName = _author?.name ?? widget.authorName ?? 'Author';

    if (_loading) {
      return Scaffold(
        appBar: ModernAppBar(title: displayName),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: ModernAppBar(title: displayName),
        body: Center(child: Text(_error!, style: TextStyle(color: colorScheme.error))),
      );
    }

    return Scaffold(
      appBar: ModernAppBar(title: displayName),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Author info card
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withAlpha(10),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: colorScheme.primaryContainer,
                    child: Text(
                      displayName.isNotEmpty ? displayName[0].toUpperCase() : 'A',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$_total publication${_total == 1 ? '' : 's'}',
                          style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Papers header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Text(
                'Publications',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          ),

          // Papers list
          if (_papers.isEmpty && !_loadingPapers)
            const SliverFillRemaining(
              child: EmptyView(message: 'No papers found for this author.'),
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
                  return _PaperListTile(paper: p);
                },
                childCount: _papers.length + (_loadingPapers || _hasMore ? 1 : 0),
              ),
            ),
        ],
      ),
    );
  }
}

class _PaperListTile extends StatelessWidget {
  const _PaperListTile({required this.paper});
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
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                if (paper.year != null) ...[
                  Icon(Icons.calendar_today, size: 12, color: colorScheme.onSurface.withAlpha(120)),
                  const SizedBox(width: 4),
                  Text(
                    '${paper.year}',
                    style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withAlpha(150)),
                  ),
                  const SizedBox(width: 12),
                ],
                Icon(Icons.format_quote, size: 12, color: colorScheme.primary.withAlpha(180)),
                const SizedBox(width: 4),
                Text(
                  '${paper.citedByCount} citations',
                  style: TextStyle(fontSize: 12, color: colorScheme.primary),
                ),
              ],
            ),
            if (paper.journal.displayName.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                paper.journal.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurface.withAlpha(140),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
