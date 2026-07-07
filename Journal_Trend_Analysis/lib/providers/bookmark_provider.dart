import 'package:flutter/foundation.dart';
import '../models/publication.dart';
import '../services/bookmark_service.dart';

class BookmarkProvider extends ChangeNotifier {
  BookmarkProvider({BookmarkService? service})
      : _service = service ?? BookmarkService();

  final BookmarkService _service;
  final Set<String> _bookmarkedIds = {};

  List<Publication> _bookmarks = [];
  List<Publication> get bookmarks => List.unmodifiable(_bookmarks);

  bool get hasBookmarks => _bookmarks.isNotEmpty;

  bool isBookmarked(String id) => _bookmarkedIds.contains(id);

  Future<void> loadBookmarks() async {
    _bookmarks = await _service.loadBookmarks();
    _bookmarkedIds.clear();
    for (final pub in _bookmarks) {
      _bookmarkedIds.add(pub.id);
    }
    notifyListeners();
  }

  Future<void> toggle(Publication pub) async {
    await _service.toggle(pub);
    if (_bookmarkedIds.contains(pub.id)) {
      _bookmarkedIds.remove(pub.id);
      _bookmarks.removeWhere((p) => p.id == pub.id);
    } else {
      _bookmarkedIds.add(pub.id);
      _bookmarks.insert(0, pub);
    }
    notifyListeners();
  }

  Future<void> remove(String id) async {
    await _service.remove(id);
    _bookmarkedIds.remove(id);
    _bookmarks.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  Future<void> clear() async {
    await _service.clear();
    _bookmarkedIds.clear();
    _bookmarks = [];
    notifyListeners();
  }
}
