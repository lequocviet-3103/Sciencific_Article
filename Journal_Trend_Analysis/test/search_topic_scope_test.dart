import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_lab2_jta/models/topic.dart';
import 'package:prm393_lab2_jta/providers/search_provider.dart';
import 'package:prm393_lab2_jta/services/paper_search_service.dart';

class _FakePaperSearchService extends PaperSearchService {
  String? lastQuery;
  SearchFilters? lastFilters;

  @override
  Future<SearchResult> searchWorks(
    String query, {
    int page = 1,
    int perPage = 20,
    SortOption sort = SortOption.citedByDesc,
    SearchFilters filters = const SearchFilters(),
  }) async {
    lastQuery = query;
    lastFilters = filters;
    return const SearchResult(
      publications: [],
      totalCount: 26,
      hasMore: false,
    );
  }
}

void main() {
  const dbTopic = Topic(
    id: '5badb724-a67a-4157-98dc-e24efcd9bf50',
    displayName: 'Computational biology',
    worksCount: 26,
  );

  test('a DB GUID selected on Home is sent as topicId', () async {
    final service = _FakePaperSearchService();
    final provider = SearchProvider(service: service);

    provider.setActiveTopic(dbTopic);
    await provider.searchWithinTopic(dbTopic.displayName);

    expect(provider.filters.topicId, dbTopic.id);
    expect(service.lastFilters?.topicId, dbTopic.id);
    expect(service.lastQuery, isEmpty);
    expect(provider.totalCount, 26);
  });

  test('clearing optional filters preserves topic until topic is cleared', () {
    final provider = SearchProvider(service: _FakePaperSearchService());

    provider.setActiveTopic(dbTopic);
    provider.setFilters(
      const SearchFilters(
        topicId: '5badb724-a67a-4157-98dc-e24efcd9bf50',
        minCitations: 10,
      ),
    );
    provider.clearFilters();

    expect(provider.filters.topicId, dbTopic.id);
    expect(provider.filters.minCitations, 0);

    provider.clearActiveTopic();
    expect(provider.filters.topicId, isNull);
  });

  test('offline fallback cards are never sent as database ids', () {
    final provider = SearchProvider(service: _FakePaperSearchService());

    provider.setActiveTopic(
      const Topic(id: 'fallback-ai', displayName: 'Artificial Intelligence'),
    );

    expect(provider.filters.topicId, isNull);
  });
}
