import 'package:flutter/foundation.dart';
import '../models/publication.dart';
import '../models/topic.dart';

/// In-memory history of publications the user has opened and topics
/// they have selected. Newest items first; capped to a small ring so
/// the home screen stays snappy.
class RecentProvider extends ChangeNotifier {
  static const int _maxItems = 12;

  final List<Publication> _publications = [];
  List<Publication> get publications => List.unmodifiable(_publications);

  final List<Topic> _topics = [];
  List<Topic> get topics => List.unmodifiable(_topics);

  /// Track a publication the user just opened. If it is already in the
  /// list (by id), it is moved to the front; otherwise it is prepended.
  void trackPublication(Publication p) {
    if (p.id.isEmpty) return;
    _publications.removeWhere((e) => e.id == p.id);
    _publications.insert(0, p);
    if (_publications.length > _maxItems) {
      _publications.removeRange(_maxItems, _publications.length);
    }
    notifyListeners();
  }

  /// Track a topic the user just selected (or just searched with).
  void trackTopic(Topic t) {
    if (t.id.isEmpty) return;
    _topics.removeWhere((e) => e.id == t.id);
    _topics.insert(0, t);
    if (_topics.length > _maxItems) {
      _topics.removeRange(_maxItems, _topics.length);
    }
    notifyListeners();
  }

  void clearPublications() {
    if (_publications.isEmpty) return;
    _publications.clear();
    notifyListeners();
  }

  void clearTopics() {
    if (_topics.isEmpty) return;
    _topics.clear();
    notifyListeners();
  }
}
