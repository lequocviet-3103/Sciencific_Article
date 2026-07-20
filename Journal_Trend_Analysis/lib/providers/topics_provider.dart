import 'package:flutter/foundation.dart';
import '../models/api_error.dart';
import '../models/topic.dart';
import '../services/paper_search_service.dart';

enum TopicsStatus { idle, loading, success, error }

class TopicsProvider extends ChangeNotifier {
  TopicsProvider({PaperSearchService? service})
      : _service = service ?? PaperSearchService();

  final PaperSearchService _service;

  TopicsStatus _status = TopicsStatus.idle;
  TopicsStatus get status => _status;

  List<Topic> _topics = [];
  List<Topic> get topics => List.unmodifiable(_topics);

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String _query = '';
  String get query => _query;

  /// Static suggestions are reserved for explicit offline/topic-picker UI.
  /// Home shows API data only so fake cards cannot be confused with rows
  /// that really exist in the database.
  static const _fallbackTopics = <Topic>[
    Topic(
      id: 'fallback-ai',
      displayName: 'Artificial Intelligence',
      subfield: 'Machine Learning',
      field: 'Computer Science',
      domain: 'Physical Sciences',
    ),
    Topic(
      id: 'fallback-ml',
      displayName: 'Machine Learning',
      subfield: 'Artificial Intelligence',
      field: 'Computer Science',
      domain: 'Physical Sciences',
    ),
    Topic(
      id: 'fallback-ds',
      displayName: 'Data Science',
      subfield: 'Data Mining',
      field: 'Computer Science',
      domain: 'Physical Sciences',
    ),
    Topic(
      id: 'fallback-sec',
      displayName: 'Cybersecurity',
      subfield: 'Security',
      field: 'Computer Science',
      domain: 'Physical Sciences',
    ),
    Topic(
      id: 'fallback-iot',
      displayName: 'Internet of Things',
      subfield: 'Networks',
      field: 'Computer Science',
      domain: 'Physical Sciences',
    ),
    Topic(
      id: 'fallback-bc',
      displayName: 'Blockchain',
      subfield: 'Distributed Computing',
      field: 'Computer Science',
      domain: 'Physical Sciences',
    ),
    Topic(
      id: 'fallback-se',
      displayName: 'Software Engineering',
      subfield: 'Software',
      field: 'Computer Science',
      domain: 'Physical Sciences',
    ),
    Topic(
      id: 'fallback-cc',
      displayName: 'Cloud Computing',
      subfield: 'Distributed Computing',
      field: 'Computer Science',
      domain: 'Physical Sciences',
    ),
    Topic(
      id: 'fallback-bio',
      displayName: 'Bioinformatics',
      subfield: 'Genomics',
      field: 'Biological Sciences',
      domain: 'Life Sciences',
    ),
    Topic(
      id: 'fallback-climate',
      displayName: 'Climate Change',
      subfield: 'Earth Sciences',
      field: 'Environmental Science',
      domain: 'Social Sciences',
    ),
    Topic(
      id: 'fallback-quantum',
      displayName: 'Quantum Computing',
      subfield: 'Quantum Physics',
      field: 'Physics',
      domain: 'Physical Sciences',
    ),
    Topic(
      id: 'fallback-gen',
      displayName: 'Genetics',
      subfield: 'Genomics',
      field: 'Biological Sciences',
      domain: 'Life Sciences',
    ),
  ];

  List<Topic> get fallbackTopics => List.unmodifiable(_fallbackTopics);

  Future<void> loadFeatured() async {
    _status = TopicsStatus.loading;
    _errorMessage = null;
    _query = '';
    notifyListeners();

    try {
      final results = await _service.fetchFeaturedTopics();
      _topics = results;
      _status = TopicsStatus.success;
    } on ApiError catch (e) {
      _topics = [];
      _errorMessage = e.message;
      _status = TopicsStatus.error;
    } catch (e) {
      _topics = [];
      _errorMessage = 'Unexpected error: $e';
      _status = TopicsStatus.error;
    }
    notifyListeners();
  }

  Future<void> searchTopics(String q) async {
    _query = q;
    if (q.trim().isEmpty) {
      await loadFeatured();
      return;
    }

    _status = TopicsStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await _service.searchTopics(q);
      _topics = results;
      _status = TopicsStatus.success;
    } on ApiError catch (e) {
      _errorMessage = e.message;
      _status = TopicsStatus.error;
    } catch (e) {
      _errorMessage = 'Unexpected error: $e';
      _status = TopicsStatus.error;
    }
    notifyListeners();
  }

  /// Group topics by their parent field so the home screen can render
  /// categorized sections.
  Map<String, List<Topic>> grouped() {
    final map = <String, List<Topic>>{};
    for (final t in _topics) {
      final key = t.field ?? t.domain ?? 'Other';
      map.putIfAbsent(key, () => []).add(t);
    }
    return map;
  }

  /// Look up a topic by id, falling back to the static fallback list so
  /// the change-topic sheet still works even when the live feed has not
  /// loaded (e.g. offline).
  Topic? findById(String id) {
    for (final t in _topics) {
      if (t.id == id) return t;
    }
    for (final t in _fallbackTopics) {
      if (t.id == id) return t;
    }
    return null;
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}
