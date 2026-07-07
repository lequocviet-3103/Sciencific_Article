import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  AnalyticsService() : _analytics = FirebaseAnalytics.instance;
  final FirebaseAnalytics _analytics;

  Future<void> logLogin({String? method}) async {
    await _analytics.logLogin(loginMethod: method ?? 'email');
    debugPrint('[Analytics] login - method: ${method ?? 'email'}');
  }

  Future<void> logRegister({String? roleId}) async {
    await _analytics.logSignUp(signUpMethod: roleId ?? 'email');
    debugPrint('[Analytics] register - role: $roleId');
  }

  Future<void> logSearchTopic(String topicId, String topicName) async {
    await _analytics.logSearch(searchTerm: topicName);
    await _analytics.logEvent(name: 'search_topic', parameters: {
      'topic_id': topicId,
      'topic_name': topicName,
    });
    debugPrint('[Analytics] search_topic - $topicName ($topicId)');
  }

  Future<void> logViewPublication(String paperId, String title) async {
    await _analytics.logEvent(name: 'view_publication', parameters: {
      'paper_id': paperId,
      'title': title,
    });
    debugPrint('[Analytics] view_publication - $title ($paperId)');
  }

  Future<void> logBookmark(String paperId, String title, bool isBookmarked) async {
    await _analytics.logEvent(name: 'bookmark', parameters: {
      'paper_id': paperId,
      'title': title,
      'action': isBookmarked ? 'add' : 'remove',
    });
    debugPrint('[Analytics] bookmark - $title ($paperId) - ${isBookmarked ? 'added' : 'removed'}');
  }

  Future<void> logExportPdf(String reportId, String? topicId) async {
    await _analytics.logEvent(name: 'export_pdf', parameters: {
      'report_id': reportId,
      if (topicId != null) 'topic_id': topicId,
    });
    debugPrint('[Analytics] export_pdf - report: $reportId');
  }

  Future<void> logDashboardView(String? topicId) async {
    await _analytics.logEvent(name: 'view_dashboard', parameters: {
      if (topicId != null) 'topic_id': topicId,
    });
    debugPrint('[Analytics] view_dashboard');
  }
}
