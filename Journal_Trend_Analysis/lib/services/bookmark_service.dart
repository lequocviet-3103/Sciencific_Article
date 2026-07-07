import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/publication.dart';

class BookmarkService {
  static const _key = 'bookmarks';

  Future<List<Publication>> loadBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_key) ?? [];
    return jsonList
        .map((s) => Publication.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
  }

  Future<Set<String>> loadIds() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_key) ?? [];
    return jsonList
        .map((s) => (jsonDecode(s) as Map<String, dynamic>)['id'] as String)
        .toSet();
  }

  Future<bool> isBookmarked(String id) async {
    final ids = await loadIds();
    return ids.contains(id);
  }

  Future<void> toggle(Publication pub) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_key) ?? [];
    final id = pub.id;

    final idx = jsonList.indexWhere((s) {
      final m = jsonDecode(s) as Map<String, dynamic>;
      return m['id'] == id;
    });

    if (idx >= 0) {
      jsonList.removeAt(idx);
    } else {
      jsonList.insert(0, jsonEncode(pub.toJson()));
    }

    await prefs.setStringList(_key, jsonList);
  }

  Future<void> remove(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_key) ?? [];
    jsonList.removeWhere((s) {
      final m = jsonDecode(s) as Map<String, dynamic>;
      return m['id'] == id;
    });
    await prefs.setStringList(_key, jsonList);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
