import 'package:flutter/foundation.dart';
import '../models/author_count.dart';
import '../models/dashboard_stats.dart';
import '../models/publication.dart';
import '../models/trend_point.dart';
import '../services/analytics_service.dart';

class DashboardProvider extends ChangeNotifier {
  DashboardProvider({AnalyticsService? service})
      : _service = service ?? AnalyticsService();

  final AnalyticsService _service;

  DashboardStats _stats = DashboardStats.empty;
  DashboardStats get stats => _stats;

  List<TrendPoint> _trend = [];
  List<TrendPoint> get trend => List.unmodifiable(_trend);

  List<Publication> _topCited = [];
  List<Publication> get topCited => List.unmodifiable(_topCited);

  List<MapEntry<String, int>> _topJournals = [];
  List<MapEntry<String, int>> get topJournals =>
      List.unmodifiable(_topJournals);

  List<AuthorCount> _topAuthors = [];
  List<AuthorCount> get topAuthors => List.unmodifiable(_topAuthors);

  /// Full per-author breakdown (not capped to top N) so the "Method"
  /// card can say e.g. "we counted N distinct names from M
  /// authorships".
  List<AuthorCount> _allAuthors = [];
  List<AuthorCount> get allAuthors => List.unmodifiable(_allAuthors);

  /// The OpenAlex search query that produced the current analytics.
  /// Shown on the dashboard / trend screens so the user always knows
  /// which dataset they are looking at.
  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  /// Total number of publications reported by the OpenAlex API for the
  /// current query. This is independent of how many records we have
  /// actually paged in (which is bounded by `maxLoadedResults`).
  int _apiTotalCount = 0;
  int get apiTotalCount => _apiTotalCount;

  bool get isReady => _stats.totalPublications > 0;

  void recompute(
    List<Publication> pubs, {
    String query = '',
    int apiTotalCount = 0,
  }) {
    _stats = _service.computeStats(pubs);
    _trend = _service.publicationsByYear(pubs);
    _topCited = _service.topCited(pubs, n: 10);
    _topJournals = _service.topJournals(pubs, n: 5);
    _allAuthors = _service.authorBreakdown(pubs);
    _topAuthors = _allAuthors.take(5).toList();
    _searchQuery = query;
    _apiTotalCount = apiTotalCount;
    debugPrint(
      '[Dashboard] pubs=${pubs.length} topJournals=${_topJournals.length} '
      'topCited=${_topCited.length} allAuthors=${_allAuthors.length}',
    );
    if (_topJournals.isEmpty) {
      final withJournal = pubs.where((p) => p.journal.name.isNotEmpty).length;
      debugPrint(
        '[Dashboard] WARN: no journals; '
        'pubsWithJournalName=$withJournal/${pubs.length}',
      );
    } else {
      debugPrint(
        '[Dashboard] topJournals sample: '
        '${_topJournals.take(3).map((e) => "${e.key}=${e.value}").toList()}',
      );
    }
    notifyListeners();
  }

  void reset() {
    _stats = DashboardStats.empty;
    _trend = [];
    _topCited = [];
    _topJournals = [];
    _topAuthors = [];
    _allAuthors = [];
    _searchQuery = '';
    _apiTotalCount = 0;
    notifyListeners();
  }
}
