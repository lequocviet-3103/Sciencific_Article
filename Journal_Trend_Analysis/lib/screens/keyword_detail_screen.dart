import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/publication.dart';
import '../services/analytics_service_flutter.dart';
import '../widgets/modern_app_bar.dart';
import '../widgets/publication_card.dart';
import 'publication_detail_screen.dart';

class KeywordDetailScreen extends StatefulWidget {
  const KeywordDetailScreen({
    super.key,
    required this.keywordId,
    required this.keywordName,
  });

  final String keywordId;
  final String keywordName;

  @override
  State<KeywordDetailScreen> createState() => _KeywordDetailScreenState();
}

class _KeywordDetailScreenState extends State<KeywordDetailScreen> {
  final _client = http.Client();
  final List<Publication> _papers = [];
  int _page = 1;
  int _total = 0;
  bool _hasMore = true;
  bool _loading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.logViewKeyword(widget.keywordName);
    _loadMore();
  }

  @override
  void dispose() {
    _client.close();
    super.dispose();
  }

  Future<void> _loadMore() async {
    if (!_hasMore && _page > 1) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();
      final uri = Uri.parse(
        '${AppConfig.apiBaseUrl}/api/keywords/${widget.keywordId}/papers',
      ).replace(queryParameters: {'page': '$_page', 'pageSize': '20'});
      final response = await _client
          .get(
            uri,
            headers: {
              'Accept': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
            },
          )
          .timeout(AppConfig.httpTimeout);
      if (response.statusCode != 200) {
        throw Exception('Server returned ${response.statusCode}');
      }
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final papers = (body['items'] as List? ?? const [])
          .map((e) => Publication.fromBackendJson(e as Map<String, dynamic>))
          .toList();
      final pageCount = (body['pageCount'] as num?)?.toInt() ?? 1;
      if (mounted) {
        setState(() {
          _papers.addAll(papers);
          _total = (body['total'] as num?)?.toInt() ?? _papers.length;
          _hasMore = _page < pageCount;
          _page++;
        });
      }
    } on TimeoutException {
      if (mounted) setState(() => _error = 'Request timed out');
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F0F1A)
          : const Color(0xFFF2F4FA),
      appBar: ModernAppBar(
        title: 'Keyword Detail',
        subtitle: widget.keywordName,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _papers.clear();
            _page = 1;
            _hasMore = true;
          });
          await _loadMore();
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: cs.outline.withAlpha(25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.keywordName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$_total related publication${_total == 1 ? '' : 's'}',
                    style: TextStyle(color: cs.outline),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),
            Text(
              'Related Publications ($_total)',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),
            if (_error != null && _papers.isEmpty)
              Center(
                child: FilledButton.icon(
                  onPressed: _loadMore,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              )
            else ...[
              for (final paper in _papers) ...[
                PublicationCard(
                  publication: paper,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          PublicationDetailScreen(publication: paper),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_hasMore)
                OutlinedButton.icon(
                  onPressed: _loadMore,
                  icon: const Icon(Icons.expand_more),
                  label: const Text('Load more'),
                )
              else if (_papers.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(30),
                  child: Center(child: Text('No publications found.')),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
