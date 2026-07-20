import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/api_error.dart';

class InsightCount {
  const InsightCount({required this.name, required this.count});

  final String name;
  final int count;

  factory InsightCount.fromJson(Map<String, dynamic> json) => InsightCount(
    name: json['name']?.toString() ?? 'Other',
    count:
        (json['paperCount'] as num?)?.toInt() ??
        (json['count'] as num?)?.toInt() ??
        0,
  );
}

class InsightYearPoint {
  const InsightYearPoint({required this.year, required this.count});

  final int year;
  final int count;

  factory InsightYearPoint.fromJson(Map<String, dynamic> json) =>
      InsightYearPoint(
        year: (json['year'] as num?)?.toInt() ?? 0,
        count: (json['count'] as num?)?.toInt() ?? 0,
      );
}

class InsightPaper {
  const InsightPaper({
    required this.paperId,
    required this.title,
    required this.citations,
    this.year,
  });

  final String paperId;
  final String title;
  final int citations;
  final int? year;

  factory InsightPaper.fromJson(Map<String, dynamic> json) => InsightPaper(
    paperId: json['paperId']?.toString() ?? '',
    title: json['title']?.toString() ?? 'Untitled',
    citations: (json['citationCount'] as num?)?.toInt() ?? 0,
    year: (json['publicationYear'] as num?)?.toInt(),
  );
}

class SearchDashboardData {
  const SearchDashboardData({
    required this.totalPublications,
    required this.totalCitations,
    required this.avgCitations,
    required this.uniqueAuthors,
    required this.publicationsByYear,
    required this.fieldBreakdown,
    required this.topPapers,
  });

  final int totalPublications;
  final int totalCitations;
  final double avgCitations;
  final int uniqueAuthors;
  final List<InsightYearPoint> publicationsByYear;
  final List<InsightCount> fieldBreakdown;
  final List<InsightPaper> topPapers;

  factory SearchDashboardData.fromJson(Map<String, dynamic> json) =>
      SearchDashboardData(
        totalPublications: (json['totalPublications'] as num?)?.toInt() ?? 0,
        totalCitations: (json['totalCitations'] as num?)?.toInt() ?? 0,
        avgCitations: (json['avgCitations'] as num?)?.toDouble() ?? 0,
        uniqueAuthors: (json['uniqueAuthors'] as num?)?.toInt() ?? 0,
        publicationsByYear: (json['publicationsByYear'] as List? ?? const [])
            .map((e) => InsightYearPoint.fromJson(e as Map<String, dynamic>))
            .toList(),
        fieldBreakdown: (json['fieldBreakdown'] as List? ?? const [])
            .map((e) => InsightCount.fromJson(e as Map<String, dynamic>))
            .toList(),
        topPapers: (json['topPapers'] as List? ?? const [])
            .map((e) => InsightPaper.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class JournalAnalyticsItem {
  const JournalAnalyticsItem({
    required this.id,
    required this.name,
    required this.paperCount,
    required this.totalCitations,
    required this.avgCitations,
  });

  final String id;
  final String name;
  final int paperCount;
  final int totalCitations;
  final double avgCitations;

  factory JournalAnalyticsItem.fromJson(Map<String, dynamic> json) =>
      JournalAnalyticsItem(
        id: json['journalId']?.toString() ?? '',
        name: json['name']?.toString() ?? 'Unknown journal',
        paperCount: (json['paperCount'] as num?)?.toInt() ?? 0,
        totalCitations: (json['totalCitations'] as num?)?.toInt() ?? 0,
        avgCitations: (json['avgCitations'] as num?)?.toDouble() ?? 0,
      );
}

class KeywordAnalyticsItem {
  const KeywordAnalyticsItem({
    required this.id,
    required this.name,
    required this.paperCount,
    required this.totalCitations,
    required this.avgCitations,
  });

  final String id;
  final String name;
  final int paperCount;
  final int totalCitations;
  final double avgCitations;

  factory KeywordAnalyticsItem.fromJson(Map<String, dynamic> json) =>
      KeywordAnalyticsItem(
        id: json['keywordId']?.toString() ?? '',
        name: json['name']?.toString() ?? 'Unknown keyword',
        paperCount: (json['paperCount'] as num?)?.toInt() ?? 0,
        totalCitations: (json['totalCitations'] as num?)?.toInt() ?? 0,
        avgCitations: (json['avgCitations'] as num?)?.toDouble() ?? 0,
      );
}

class ResearchInsightsService {
  ResearchInsightsService({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  Future<Map<String, String>> _headers() async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    return {
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<SearchDashboardData> getDashboard({
    String? topicId,
    String? query,
  }) async {
    final params = <String, String>{
      if (topicId != null && topicId.isNotEmpty) 'topicId': topicId,
      if ((topicId == null || topicId.isEmpty) &&
          query != null &&
          query.trim().isNotEmpty)
        'q': query.trim(),
    };
    final uri = Uri.parse(
      '${AppConfig.apiBaseUrl}/api/dashboard',
    ).replace(queryParameters: params);
    final json = await _getObject(uri, 'Could not load dashboard');
    return SearchDashboardData.fromJson(json);
  }

  Future<List<JournalAnalyticsItem>> getTopJournals({int take = 10}) async {
    final uri = Uri.parse(
      '${AppConfig.apiBaseUrl}/api/journals/top',
    ).replace(queryParameters: {'take': '$take'});
    final list = await _getList(uri, 'Could not load journals');
    return list.map(JournalAnalyticsItem.fromJson).toList();
  }

  Future<List<KeywordAnalyticsItem>> getTopKeywords({int take = 10}) async {
    final uri = Uri.parse(
      '${AppConfig.apiBaseUrl}/api/keywords/popular',
    ).replace(queryParameters: {'take': '$take'});
    final list = await _getList(uri, 'Could not load keywords');
    return list.map(KeywordAnalyticsItem.fromJson).toList();
  }

  Future<Map<String, dynamic>> _getObject(Uri uri, String message) async {
    try {
      final response = await _client
          .get(uri, headers: await _headers())
          .timeout(AppConfig.httpTimeout);
      if (response.statusCode != 200) {
        throw ApiError(message, statusCode: response.statusCode);
      }
      return jsonDecode(response.body) as Map<String, dynamic>;
    } on TimeoutException {
      throw const ApiError('Request timed out. Please try again.');
    }
  }

  Future<List<Map<String, dynamic>>> _getList(Uri uri, String message) async {
    try {
      final response = await _client
          .get(uri, headers: await _headers())
          .timeout(AppConfig.httpTimeout);
      if (response.statusCode != 200) {
        throw ApiError(message, statusCode: response.statusCode);
      }
      return (jsonDecode(response.body) as List)
          .map((e) => e as Map<String, dynamic>)
          .toList();
    } on TimeoutException {
      throw const ApiError('Request timed out. Please try again.');
    }
  }

  void dispose() => _client.close();
}
