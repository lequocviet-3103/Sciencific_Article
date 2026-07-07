import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import '../config/app_config.dart';
import '../models/api_error.dart';

class TrendPoint {
  final int year;
  final int count;
  const TrendPoint({required this.year, required this.count});

  factory TrendPoint.fromJson(Map<String, dynamic> json) =>
      TrendPoint(year: json['year'] as int, count: json['count'] as int);
}

class KeywordTrend {
  final String keyword;
  final List<TrendPoint> trend;
  const KeywordTrend({required this.keyword, required this.trend});
}

class EmergingTopic {
  final String topicId;
  final String name;
  final String? field;
  final String? domain;
  final int recentCount;
  final int totalCount;
  final double growthRatio;

  const EmergingTopic({
    required this.topicId,
    required this.name,
    this.field,
    this.domain,
    required this.recentCount,
    required this.totalCount,
    required this.growthRatio,
  });

  factory EmergingTopic.fromJson(Map<String, dynamic> json) => EmergingTopic(
        topicId: json['topicId']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        field: json['field']?.toString(),
        domain: json['domain']?.toString(),
        recentCount: json['recentCount'] as int? ?? 0,
        totalCount: json['totalCount'] as int? ?? 0,
        growthRatio: (json['growthRatio'] as num?)?.toDouble() ?? 0.0,
      );
}

class AuthorInfo {
  final String authorId;
  final String name;
  final String? externalAuthorId;
  final int paperCount;

  const AuthorInfo({
    required this.authorId,
    required this.name,
    this.externalAuthorId,
    required this.paperCount,
  });

  factory AuthorInfo.fromJson(Map<String, dynamic> json) => AuthorInfo(
        authorId: json['authorId']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        externalAuthorId: json['externalAuthorId']?.toString(),
        paperCount: json['paperCount'] as int? ?? 0,
      );
}

class JournalInfo {
  final String journalId;
  final String name;
  final String? publisher;
  final String? issn;
  final int paperCount;

  const JournalInfo({
    required this.journalId,
    required this.name,
    this.publisher,
    this.issn,
    required this.paperCount,
  });

  factory JournalInfo.fromJson(Map<String, dynamic> json) => JournalInfo(
        journalId: json['journalId']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        publisher: json['publisher']?.toString(),
        issn: json['issn']?.toString(),
        paperCount: json['paperCount'] as int? ?? 0,
      );
}

class AnalysisService {
  AnalysisService({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;

  Future<Map<String, String>> _headers() async {
    final user = FirebaseAuth.instance.currentUser;
    final idToken = user != null ? await user.getIdToken() : null;
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (idToken != null) 'Authorization': 'Bearer $idToken',
    };
  }

  // ── Topic trend ─────────────────────────────────────────────────────────────

  Future<KeywordTrend> getTopicTrend(
    String keyword, {
    int? fromYear,
    int? toYear,
  }) async {
    final params = <String, String>{'q': keyword};
    if (fromYear != null) params['fromYear'] = fromYear.toString();
    if (toYear != null) params['toYear'] = toYear.toString();

    final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/analysis/topic-trend')
        .replace(queryParameters: params);
    final response =
        await _client.get(uri, headers: await _headers()).timeout(AppConfig.httpTimeout);

    if (response.statusCode != 200) {
      throw ApiError('Failed to load trend', statusCode: response.statusCode);
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return KeywordTrend(
      keyword: body['keyword']?.toString() ?? keyword,
      trend: ((body['trend'] as List?) ?? [])
          .map((e) => TrendPoint.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  // ── Compare keywords ─────────────────────────────────────────────────────────

  Future<List<KeywordTrend>> compareKeywords(
    List<String> keywords, {
    int? fromYear,
    int? toYear,
  }) async {
    final body = <String, dynamic>{
      'keywords': keywords,
      'fromYear': fromYear,
      'toYear': toYear,
    }..removeWhere((_, v) => v == null);

    final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/analysis/compare-keywords');
    final response = await _client
        .post(uri, headers: await _headers(), body: jsonEncode(body))
        .timeout(AppConfig.httpTimeout);

    if (response.statusCode != 200) {
      throw ApiError('Failed to compare keywords', statusCode: response.statusCode);
    }

    final list = jsonDecode(response.body) as List;
    return list.map((e) {
      final map = e as Map<String, dynamic>;
      return KeywordTrend(
        keyword: map['keyword']?.toString() ?? '',
        trend: ((map['trend'] as List?) ?? [])
            .map((t) => TrendPoint.fromJson(t as Map<String, dynamic>))
            .toList(),
      );
    }).toList();
  }

  // ── Emerging topics ──────────────���─────────────────────���─────────────────────

  Future<List<EmergingTopic>> getEmergingTopics({int take = 10}) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/analysis/emerging-topics')
        .replace(queryParameters: {'take': take.toString()});
    final response =
        await _client.get(uri, headers: await _headers()).timeout(AppConfig.httpTimeout);

    if (response.statusCode != 200) {
      throw ApiError('Failed to load emerging topics', statusCode: response.statusCode);
    }

    final list = jsonDecode(response.body) as List;
    return list
        .map((e) => EmergingTopic.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Authors ─────���────────────────────────────────────────────────────────────

  Future<List<AuthorInfo>> getTopAuthors({int take = 10}) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/authors/top')
        .replace(queryParameters: {'take': take.toString()});
    final response =
        await _client.get(uri, headers: await _headers()).timeout(AppConfig.httpTimeout);

    if (response.statusCode != 200) {
      throw ApiError('Failed to load top authors', statusCode: response.statusCode);
    }

    final list = jsonDecode(response.body) as List;
    return list
        .map((e) => AuthorInfo(
              authorId: (e as Map)['authorId']?.toString() ?? '',
              name: e['name']?.toString() ?? '',
              paperCount: e['paperCount'] as int? ?? 0,
            ))
        .toList();
  }

  Future<AuthorInfo> getAuthorById(String authorId) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/authors/$authorId');
    final response =
        await _client.get(uri, headers: await _headers()).timeout(AppConfig.httpTimeout);

    if (response.statusCode != 200) {
      throw ApiError('Author not found', statusCode: response.statusCode);
    }

    return AuthorInfo.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  // ── Journals ───────��────────────────────────────────���────────────────────────

  Future<List<JournalInfo>> getTopJournals({int take = 10}) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/journals/top')
        .replace(queryParameters: {'take': take.toString()});
    final response =
        await _client.get(uri, headers: await _headers()).timeout(AppConfig.httpTimeout);

    if (response.statusCode != 200) {
      throw ApiError('Failed to load top journals', statusCode: response.statusCode);
    }

    final list = jsonDecode(response.body) as List;
    return list
        .map((e) => JournalInfo(
              journalId: (e as Map)['journalId']?.toString() ?? '',
              name: e['name']?.toString() ?? '',
              paperCount: e['paperCount'] as int? ?? 0,
            ))
        .toList();
  }

  Future<JournalInfo> getJournalById(String journalId) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/journals/$journalId');
    final response =
        await _client.get(uri, headers: await _headers()).timeout(AppConfig.httpTimeout);

    if (response.statusCode != 200) {
      throw ApiError('Journal not found', statusCode: response.statusCode);
    }

    return JournalInfo.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  // ── Admin ─────��───────────────────────────��───────────────────────────────────

  Future<Map<String, dynamic>> getAdminDashboard() async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/admin/dashboard');
    final response =
        await _client.get(uri, headers: await _headers()).timeout(AppConfig.httpTimeout);

    if (response.statusCode != 200) {
      throw ApiError('Failed to load admin dashboard', statusCode: response.statusCode);
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<List<dynamic>> getSyncLogs({int take = 50}) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/admin/sync/logs')
        .replace(queryParameters: {'take': take.toString()});
    final response =
        await _client.get(uri, headers: await _headers()).timeout(AppConfig.httpTimeout);

    if (response.statusCode != 200) {
      throw ApiError('Failed to load sync logs', statusCode: response.statusCode);
    }

    return jsonDecode(response.body) as List;
  }

  Future<void> banUser(String userId) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/admin/users/$userId/ban');
    final response =
        await _client.put(uri, headers: await _headers()).timeout(AppConfig.httpTimeout);
    if (response.statusCode != 200) {
      throw ApiError('Failed to ban user', statusCode: response.statusCode);
    }
  }

  Future<void> unbanUser(String userId) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/admin/users/$userId/unban');
    final response =
        await _client.put(uri, headers: await _headers()).timeout(AppConfig.httpTimeout);
    if (response.statusCode != 200) {
      throw ApiError('Failed to unban user', statusCode: response.statusCode);
    }
  }

  void dispose() => _client.close();
}
