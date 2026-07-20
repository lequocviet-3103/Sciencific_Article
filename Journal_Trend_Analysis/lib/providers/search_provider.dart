import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import '../config/app_config.dart';
import '../models/api_error.dart';
import '../models/publication.dart';
import '../models/topic.dart';
import '../services/paper_search_service.dart';
import '../services/analytics_service_flutter.dart';
import '../services/remote_config_service.dart';
import '../services/search_history_service.dart';

enum SearchStatus { idle, loading, success, error }

class SearchProvider extends ChangeNotifier {
  SearchProvider({
    PaperSearchService? service,
    SearchHistoryService? historyService,
    AnalyticsService? analyticsService,
    RemoteConfigService? remoteConfigService,
  }) : _service = service ?? PaperSearchService(),
       _historyService = historyService ?? SearchHistoryService(),
       _analytics = analyticsService ?? AnalyticsService.instance,
       _remoteConfig = remoteConfigService ?? RemoteConfigService.instance;

  final PaperSearchService _service;
  final SearchHistoryService _historyService;
  final AnalyticsService _analytics;
  final RemoteConfigService _remoteConfig;

  int get _resultLimit => _remoteConfig.maxSearchResults;
  int get _pageSize => math.min(AppConfig.defaultPerPage, _resultLimit);

  /// Hook called every time a search successfully finishes. The
  /// `DashboardProvider` registers itself here so the analytics it
  /// exposes (Top Authors / Fields / Trends) always reflect the
  /// latest search, regardless of which screen triggered it.
  void Function(List<Publication> pubs, String query, int total)? _onSuccess;

  void attachDashboardHook(void Function(List<Publication>, String, int) hook) {
    _onSuccess = hook;
  }

  /// Lightweight hook for the Profile screen — fires after every
  /// successful search with just the query string. We use a separate
  /// hook (instead of packing it into `_onSuccess`) so the profile
  /// does not need to listen to the bulky publication list.
  void Function(String query)? _onProfileSearch;

  void attachProfileHook(void Function(String) hook) {
    _onProfileSearch = hook;
  }

  String _query = '';
  String get query => _query;

  /// The query that is actually sent to the API. When the user is
  /// searching within a topic, this differs from [query] because it
  /// includes the topic name so the OpenAlex results stay in scope.
  String _effectiveQuery = '';
  String get effectiveQuery => _effectiveQuery;

  Topic? _activeTopic;
  Topic? get activeTopic => _activeTopic;

  List<Publication> _publications = [];
  List<Publication> get publications => List.unmodifiable(_publications);

  SearchStatus _status = SearchStatus.idle;
  SearchStatus get status => _status;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool get hasResults => _publications.isNotEmpty;

  int _totalCount = 0;
  int get totalCount => _totalCount;

  bool _hasMore = false;
  bool get hasMore => _hasMore;

  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;

  int _currentPage = 1;

  SortOption _sortOption = SortOption.citedByDesc;
  SortOption get sortOption => _sortOption;

  SearchFilters _filters = const SearchFilters();
  SearchFilters get filters => _filters;

  List<String> _history = [];
  List<String> get history => List.unmodifiable(_history);

  Future<void> loadHistory() async {
    _history = await _historyService.load();
    notifyListeners();
  }

  void setFilters(SearchFilters f) {
    _filters = f;
    notifyListeners();
  }

  void clearFilters() {
    // Keep the topic selected on Home while clearing optional filters.
    _filters = SearchFilters(topicId: _backendTopicId(_activeTopic));
    notifyListeners();
    if (_query.isNotEmpty) search(_query);
  }

  Future<void> search(String topic) async {
    final trimmed = topic.trim();
    if (trimmed.isEmpty) return;

    _query = trimmed;
    _effectiveQuery = trimmed;
    _currentPage = 1;
    _status = SearchStatus.loading;
    _errorMessage = null;
    _publications = [];
    // A bare search removes any active topic scope so we always show
    // the user a global result set, regardless of how they got here.
    if (_activeTopic == null && _filters.topicId != null) {
      _filters = _filters.copyWith(clearTopicId: true);
    }
    notifyListeners();
    await _analytics.logSearchTopic(trimmed);

    // When scoped to a topic, drop the free-text `q` so the BE returns
    // every paper in the topic rather than only the few whose title
    // happens to mention the keyword. The topic filter alone is the
    // authoritative scope; the user's typed text would otherwise silently
    // hide most papers ("I picked Humanities — why don't I see all 8?").
    final hasTopicScope =
        _filters.topicId != null && _filters.topicId!.isNotEmpty;
    final queryForService = hasTopicScope ? '' : trimmed;

    try {
      final result = await _service.searchWorks(
        queryForService,
        page: 1,
        perPage: _pageSize,
        sort: _sortOption,
        filters: _filters,
      );
      _publications = result.publications.take(_resultLimit).toList();
      _totalCount = result.totalCount;
      _hasMore = result.hasMore && _publications.length < _resultLimit;
      _status = SearchStatus.success;
      await _addToHistory(trimmed);
      // Fire the dashboard hook so analytics are always in sync
      // with the current search, no matter which screen triggered
      // it (TopicsScreen, SearchScreen, history re-run, etc.).
      _onSuccess?.call(_publications, trimmed, result.totalCount);
      _onProfileSearch?.call(trimmed);
    } on ApiError catch (e) {
      _errorMessage = e.message;
      _status = SearchStatus.error;
    } catch (e) {
      _errorMessage = 'Unexpected error: $e';
      _status = SearchStatus.error;
    }

    notifyListeners();
  }

  /// Refine the current results without leaving the active topic.
  /// The user-facing [query] stays as the raw keyword.
  ///
  /// Strategy — depending on what kind of id the active topic carries:
  ///  * Real OpenAlex id (e.g. `T11223344`): scope the request via the
  ///    `topics.id` filter so OpenAlex only returns papers tagged with
  ///    that exact topic.
  ///  * Fallback / placeholder id (e.g. `fallback-ai`): no filter is
  ///    possible, so fall back to a full-text search that includes the
  ///    topic name so results are at least conceptually in-scope.
  Future<void> searchWithinTopic(String keyword) async {
    if (_activeTopic == null) {
      return search(keyword);
    }
    final trimmed = keyword.trim();
    if (trimmed.isEmpty) return;

    final topicId = _backendTopicId(_activeTopic);
    final hasRealId = topicId != null;

    _query = trimmed;
    _effectiveQuery = hasRealId
        ? trimmed
        : '$trimmed ${_activeTopic!.displayName}';
    _currentPage = 1;
    _status = SearchStatus.loading;
    _errorMessage = null;
    _publications = [];

    if (hasRealId) {
      _filters = _filters.copyWith(topicId: topicId, clearTopicId: false);
    } else {
      // No real topic id available (e.g. fallback list); clear the
      // filter and scope the search textually instead.
      _filters = _filters.copyWith(clearTopicId: true);
    }
    notifyListeners();
    await _analytics.logSearchTopic(trimmed);

    // When we have a real topic id the BE handles the topic scope, so we
    // pass an empty `q` to avoid narrowing further by keyword. Without a
    // real topic id we keep the keyword (plus the topic name) so the
    // fallback textual scoping still works.
    final queryForService = hasRealId ? '' : _effectiveQuery;

    try {
      final result = await _service.searchWorks(
        queryForService,
        page: 1,
        perPage: _pageSize,
        sort: _sortOption,
        filters: _filters,
      );
      _publications = result.publications.take(_resultLimit).toList();
      _totalCount = result.totalCount;
      _hasMore = result.hasMore && _publications.length < _resultLimit;
      _status = SearchStatus.success;
      await _addToHistory(trimmed);
      _onSuccess?.call(_publications, _effectiveQuery, result.totalCount);
      _onProfileSearch?.call(trimmed);
    } on ApiError catch (e) {
      _errorMessage = e.message;
      _status = SearchStatus.error;
    } catch (e) {
      _errorMessage = 'Unexpected error: $e';
      _status = SearchStatus.error;
    }
    notifyListeners();
  }

  /// Return the ResearchTopic.TopicId exposed by our API. Offline
  /// suggestions intentionally use fallback ids and cannot filter the DB.
  static String? _backendTopicId(Topic? topic) {
    final id = topic?.id.trim();
    if (id == null || id.isEmpty || id.startsWith('fallback-')) return null;
    return id;
  }

  /// Run a search that was triggered by selecting a topic from TopicsScreen.
  /// Stores the topic so the results screen can show its category/field.
  Future<void> searchByTopic(Topic topic) async {
    setActiveTopic(topic);
    await search(topic.displayName);
  }

  void setActiveTopic(Topic? topic) {
    _activeTopic = topic;
    // Keep _filters.topicId in sync with the active topic so any subsequent
    // search call carries the topic scope to the backend. Without this the
    // active topic pill would render but the BE request would be missing
    // the topicId filter — dropping the user back to a global search.
    if (topic == null) {
      _filters = _filters.copyWith(clearTopicId: true);
    } else {
      final topicId = _backendTopicId(topic);
      _filters = topicId == null
          ? _filters.copyWith(clearTopicId: true)
          : _filters.copyWith(topicId: topicId);
    }
    notifyListeners();
  }

  /// Clears the active topic so subsequent searches are unfiltered. Does
  /// not touch the current query or results.
  void clearActiveTopic() {
    _activeTopic = null;
    _filters = _filters.copyWith(clearTopicId: true);
    notifyListeners();
  }

  Future<void> loadMore() async {
    if (!_hasMore || _isLoadingMore || _query.isEmpty) return;
    // Hard cap: stop auto-paginating once the user has already loaded the
    // configured maximum number of results. The list will still show a
    // "Load more" button so the user can opt-in to more.
    if (_publications.length >= _resultLimit) {
      _hasMore = false;
      notifyListeners();
      return;
    }

    _isLoadingMore = true;
    notifyListeners();

    // Mirror the same drop-`q`-when-topic-scoped behaviour as search()
    // and searchWithinTopic() so pagination stays consistent with the
    // initial request.
    final hasTopicScope =
        _filters.topicId != null && _filters.topicId!.isNotEmpty;
    final queryForService = hasTopicScope ? '' : _query;

    try {
      final result = await _service.searchWorks(
        queryForService,
        page: _currentPage + 1,
        perPage: _pageSize,
        sort: _sortOption,
        filters: _filters,
      );
      _currentPage++;
      _publications = [..._publications, ...result.publications];
      // Re-check cap after appending: another page may have pushed us over.
      if (_publications.length >= _resultLimit) {
        _publications = _publications.sublist(0, _resultLimit);
        _hasMore = false;
      } else {
        _hasMore = result.hasMore;
      }
      // Refresh dashboard analytics over the full corpus now that
      // more papers are in scope.
      _onSuccess?.call(_publications, _query, _totalCount);
    } on ApiError catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Unexpected error: $e';
    }

    _isLoadingMore = false;
    notifyListeners();
  }

  void setSort(SortOption option) {
    if (_sortOption == option) return;
    _sortOption = option;
    if (_query.isNotEmpty) search(_query);
  }

  Future<void> _addToHistory(String q) async {
    _history.remove(q);
    _history.insert(0, q);
    if (_history.length > 8) _history.removeLast();
    await _historyService.save(_history);
    notifyListeners();
  }

  Future<void> clearHistory() async {
    _history = [];
    await _historyService.clear();
    notifyListeners();
  }

  void clear() {
    _query = '';
    _effectiveQuery = '';
    _publications = [];
    _status = SearchStatus.idle;
    _errorMessage = null;
    _totalCount = 0;
    _hasMore = false;
    _isLoadingMore = false;
    _currentPage = 1;
    _activeTopic = null;
    _filters = const SearchFilters();
    notifyListeners();
  }

  /// Re-run the current search, preserving the active topic if any.
  /// Used by pull-to-refresh and filter changes.
  Future<void> refreshCurrent() async {
    if (_query.isEmpty) return;
    if (_activeTopic != null) {
      await searchWithinTopic(_query);
    } else {
      await search(_query);
    }
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}
