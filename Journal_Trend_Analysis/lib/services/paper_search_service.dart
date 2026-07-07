import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import '../config/app_config.dart';
import '../models/api_error.dart';
import '../models/publication.dart';
import '../models/topic.dart';

enum SortOption {
  citedByDesc('cited_by_count:desc', 'Most Cited'),
  citedByAsc('cited_by_count:asc', 'Least Cited'),
  yearDesc('publication_year:desc', 'Newest First'),
  yearAsc('publication_year:asc', 'Oldest First'),
  relevance('relevance_score:desc', 'Most Relevant');

  final String apiValue;
  final String label;
  const SortOption(this.apiValue, this.label);
}

class SearchFilters {
  const SearchFilters({
    this.fromYear,
    this.toYear,
    this.minCitations = 0,
    this.type,
    this.topicId,
    this.authorName,
    this.journalName,
  });

  final int? fromYear;
  final int? toYear;
  final int minCitations;
  final String? type;

  /// Backend topic id (ResearchTopic.TopicId) to scope results to.
  final String? topicId;

  /// Free-text author name filter passed to /api/papers?authorName=
  final String? authorName;

  /// Free-text journal name filter passed to /api/papers?journalName=
  final String? journalName;

  bool get isActive =>
      fromYear != null ||
      toYear != null ||
      minCitations > 0 ||
      type != null ||
      topicId != null ||
      (authorName != null && authorName!.isNotEmpty) ||
      (journalName != null && journalName!.isNotEmpty);

  SearchFilters copyWith({
    int? fromYear,
    int? toYear,
    int? minCitations,
    String? type,
    String? topicId,
    String? authorName,
    String? journalName,
    bool clearFromYear = false,
    bool clearToYear = false,
    bool clearType = false,
    bool clearTopicId = false,
    bool clearAuthorName = false,
    bool clearJournalName = false,
  }) {
    return SearchFilters(
      fromYear: clearFromYear ? null : (fromYear ?? this.fromYear),
      toYear: clearToYear ? null : (toYear ?? this.toYear),
      minCitations: minCitations ?? this.minCitations,
      type: clearType ? null : (type ?? this.type),
      topicId: clearTopicId ? null : (topicId ?? this.topicId),
      authorName: clearAuthorName ? null : (authorName ?? this.authorName),
      journalName: clearJournalName ? null : (journalName ?? this.journalName),
    );
  }

  SearchFilters clear() => const SearchFilters();

  static const docTypes = [
    ('journal-article', 'Journal Article'),
    ('proceedings-article', 'Conference Paper'),
    ('book', 'Book'),
    ('book-chapter', 'Book Chapter'),
    ('dissertation', 'Dissertation'),
    ('preprint', 'Preprint'),
  ];
}

class SearchResult {
  const SearchResult({
    required this.publications,
    required this.totalCount,
    required this.hasMore,
  });

  final List<Publication> publications;
  final int totalCount;
  final bool hasMore;
}

/// Client for the .NET backend's DB-backed paper/topic search
/// (`/api/papers`, `/api/topics`). The backend persists matching OpenAlex
/// results into Postgres on the first search for a new term (see
/// OpenAlexSyncService.EnsureWorksSyncedForQueryAsync), so this app never
/// talks to OpenAlex directly — every call here only ever hits our own API.
class PaperSearchService {
  PaperSearchService({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;

  Future<Map<String, String>> _headers() async {
    final user = FirebaseAuth.instance.currentUser;
    final idToken = user != null ? await user.getIdToken() : null;
    return {
      'Accept': 'application/json',
      if (idToken != null) 'Authorization': 'Bearer $idToken',
    };
  }

  Future<SearchResult> searchWorks(
    String query, {
    int page = 1,
    int perPage = AppConfig.defaultPerPage,
    SortOption sort = SortOption.citedByDesc,
    SearchFilters filters = const SearchFilters(),
  }) async {
    final params = <String, String>{
      'q': query,
      'page': page.toString(),
      'pageSize': perPage.toString(),
      'sort': sort.apiValue,
    };
    if (filters.fromYear != null) params['fromYear'] = filters.fromYear.toString();
    if (filters.toYear != null) params['toYear'] = filters.toYear.toString();
    if (filters.minCitations > 0) params['minCitations'] = filters.minCitations.toString();
    if (filters.type != null) params['docType'] = filters.type!;
    if (filters.topicId != null && filters.topicId!.isNotEmpty) {
      params['topicId'] = filters.topicId!;
    }
    if (filters.authorName != null && filters.authorName!.isNotEmpty) {
      params['authorName'] = filters.authorName!;
    }
    if (filters.journalName != null && filters.journalName!.isNotEmpty) {
      params['journalName'] = filters.journalName!;
    }

    final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/papers').replace(queryParameters: params);

    http.Response response;
    try {
      response = await _client.get(uri, headers: await _headers()).timeout(AppConfig.httpTimeout);
    } on TimeoutException {
      throw const ApiError('Request timed out. Check your connection and try again.');
    } catch (e) {
      throw ApiError('Network error: $e');
    }

    if (response.statusCode != 200) {
      throw ApiError('Search failed', statusCode: response.statusCode);
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final items = (body['items'] as List?) ?? const [];
    final total = body['total'] as int? ?? 0;
    final pageCount = body['pageCount'] as int? ?? 1;

    return SearchResult(
      publications: items
          .map((e) => Publication.fromBackendJson(e as Map<String, dynamic>))
          .toList(),
      totalCount: total,
      hasMore: page < pageCount,
    );
  }

  /// Fetch a curated list of popular research topics to present to the user
  /// before they run a search. Falls back to a static list on error so the
  /// home screen is never empty.
  Future<List<Topic>> fetchFeaturedTopics({int perPage = 50}) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/topics/featured')
        .replace(queryParameters: {'take': perPage.toString()});

    http.Response response;
    try {
      response = await _client.get(uri, headers: await _headers()).timeout(AppConfig.httpTimeout);
    } on TimeoutException {
      throw const ApiError('Request timed out. Check your connection and try again.');
    } catch (e) {
      throw ApiError('Network error: $e');
    }

    if (response.statusCode != 200) {
      throw ApiError('Failed to load topics', statusCode: response.statusCode);
    }

    final list = jsonDecode(response.body) as List<dynamic>;
    return list.map((e) => Topic.fromBackendJson(e as Map<String, dynamic>)).toList();
  }

  /// Search topics by free-text so users can find a topic to start with.
  Future<List<Topic>> searchTopics(String query, {int perPage = 25}) async {
    if (query.trim().isEmpty) return fetchFeaturedTopics(perPage: perPage);

    final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/topics')
        .replace(queryParameters: {'q': query.trim(), 'take': perPage.toString()});

    http.Response response;
    try {
      response = await _client.get(uri, headers: await _headers()).timeout(AppConfig.httpTimeout);
    } on TimeoutException {
      throw const ApiError('Request timed out. Check your connection and try again.');
    } catch (e) {
      throw ApiError('Network error: $e');
    }

    if (response.statusCode != 200) {
      throw ApiError('Failed to load topics', statusCode: response.statusCode);
    }

    final list = jsonDecode(response.body) as List<dynamic>;
    return list.map((e) => Topic.fromBackendJson(e as Map<String, dynamic>)).toList();
  }

  /// Fetch a single paper by its backend PaperId with full details
  /// (abstract, authors, topics). Used when navigating to the detail
  /// screen so the user sees the full record.
  Future<Publication> fetchWorkById(String paperId) async {
    // URL-encode the paperId so OpenAlex-style IDs (https://openalex.org/W...)
    // don't break ASP.NET Core routing when the slashes are treated as path
    // separators.
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/papers/${Uri.encodeComponent(paperId)}');

    http.Response response;
    try {
      response = await _client.get(uri, headers: await _headers()).timeout(AppConfig.httpTimeout);
    } on TimeoutException {
      throw const ApiError('Request timed out. Check your connection and try again.');
    } catch (e) {
      throw ApiError('Network error: $e');
    }

    if (response.statusCode != 200) {
      throw ApiError('Failed to load paper', statusCode: response.statusCode);
    }

    return Publication.fromBackendJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  void dispose() {
    _client.close();
  }
}
