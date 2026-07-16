import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import '../config/app_config.dart';
import '../models/api_error.dart';
import '../models/publication.dart';

class BackendPaperService {
  BackendPaperService({http.Client? client})
    : _client = client ?? http.Client();
  final http.Client _client;

  Future<Map<String, String>> _headers() async {
    final user = FirebaseAuth.instance.currentUser;
    final idToken = user != null ? await user.getIdToken() : null;
    return {
      'Content-Type': 'application/json',
      if (idToken != null) 'Authorization': 'Bearer $idToken',
    };
  }

  Future<BackendSearchResult> searchPapers({
    String? query,
    int page = 1,
    int pageSize = 20,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'pageSize': pageSize.toString(),
    };
    if (query != null && query.isNotEmpty) {
      params['q'] = query;
    }

    final uri = Uri.parse(
      '${AppConfig.apiBaseUrl}/api/papers',
    ).replace(queryParameters: params);

    final response = await _client.get(uri, headers: await _headers());

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiError(
        'Backend error: ${response.statusCode}',
        statusCode: response.statusCode,
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final items = data['items'] as List<dynamic>? ?? [];
    final total = data['total'] as int? ?? 0;

    final publications = items
        .map((e) => Publication.fromBackendJson(e as Map<String, dynamic>))
        .toList();

    return BackendSearchResult(
      publications: publications,
      totalCount: total,
      page: page,
      pageSize: pageSize,
      pageCount: data['pageCount'] as int? ?? 1,
    );
  }

  Future<Publication?> getPaperById(String paperId) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/papers/$paperId');
    final response = await _client.get(uri, headers: await _headers());

    if (response.statusCode == 404) return null;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiError(
        'Backend error: ${response.statusCode}',
        statusCode: response.statusCode,
      );
    }

    return Publication.fromBackendJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  /// Returns {paperCount, authorCount, journalCount, topicCount} from the DB.
  Future<Map<String, int>> getStats() async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/stats');
    final response = await _client
        .get(uri, headers: await _headers())
        .timeout(AppConfig.httpTimeout);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiError('Stats failed', statusCode: response.statusCode);
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return {
      'paperCount': data['paperCount'] as int? ?? 0,
      'authorCount': data['authorCount'] as int? ?? 0,
      'journalCount': data['journalCount'] as int? ?? 0,
      'topicCount': data['topicCount'] as int? ?? 0,
    };
  }

  /// Fetches the top cited papers from the DB.
  Future<List<Publication>> getTopPapers({int take = 10}) async {
    final uri = Uri.parse(
      '${AppConfig.apiBaseUrl}/api/papers/popular',
    ).replace(queryParameters: {'take': take.toString()});
    final response = await _client
        .get(uri, headers: await _headers())
        .timeout(AppConfig.httpTimeout);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiError(
        'Failed to load top papers',
        statusCode: response.statusCode,
      );
    }

    final list = jsonDecode(response.body) as List;
    return list
        .map((e) => Publication.fromBackendJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<String> triggerSync() async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/sync/works');
    final response = await _client.post(uri, headers: await _headers());

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiError(
        'Sync failed: ${response.statusCode}',
        statusCode: response.statusCode,
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['message']?.toString() ?? 'Sync completed';
  }

  Future<String> triggerRecomputeTrends() async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/sync/trends');
    final response = await _client.post(uri, headers: await _headers());

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiError(
        'Recompute failed: ${response.statusCode}',
        statusCode: response.statusCode,
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['message']?.toString() ?? 'Trends recomputed';
  }

  void dispose() => _client.close();
}

class BackendSearchResult {
  final List<Publication> publications;
  final int totalCount;
  final int page;
  final int pageSize;
  final int pageCount;

  BackendSearchResult({
    required this.publications,
    required this.totalCount,
    required this.page,
    required this.pageSize,
    required this.pageCount,
  });

  bool get hasMore => page < pageCount;
}
