import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  AnalyticsService._() : _analytics = FirebaseAnalytics.instance;

  static final AnalyticsService instance = AnalyticsService._();
  final FirebaseAnalytics _analytics;

  Future<void> logLogin({required String method}) =>
      _log('login', {'method': method});

  Future<void> logRegister({String? roleId}) =>
      _log('sign_up', {'method': roleId ?? 'email'});

  Future<void> logSearchTopic(String keyword) =>
      _log('search_topic', {'keyword': keyword});

  Future<void> logViewPublication(String title, int year) => _log(
    'view_publication',
    {'publication_title': title, 'publication_year': year},
  );

  Future<void> logViewJournal(String journalName) =>
      _log('view_journal', {'journal_name': journalName});

  Future<void> logViewKeyword(String keyword) =>
      _log('view_keyword', {'keyword': keyword});

  Future<void> logBookmark(String paperId, String title, bool isBookmarked) =>
      _log('bookmark', {
        'paper_id': paperId,
        'title': title,
        'action': isBookmarked ? 'add' : 'remove',
      });

  Future<void> logExportPdf(String topic) =>
      _log('export_pdf', {'topic': topic});

  Future<void> logLogout() => _log('logout');

  Future<void> logDashboardView(String? topicId) =>
      _log('view_dashboard', {if (topicId != null) 'topic_id': topicId});

  Future<void> _log(String name, [Map<String, Object>? parameters]) async {
    try {
      await _analytics.logEvent(name: name, parameters: parameters);
      debugPrint('[Analytics] $name ${parameters ?? ''}');
    } catch (error, stackTrace) {
      debugPrint('[Analytics] failed to log $name: $error');
      await FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace,
        reason: 'Firebase Analytics event failed: $name',
        fatal: false,
      );
    }
  }
}
