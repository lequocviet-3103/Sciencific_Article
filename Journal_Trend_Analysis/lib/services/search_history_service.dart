import 'package:shared_preferences/shared_preferences.dart';

class SearchHistoryService {
  static const _key = 'search_history';
  static const _maxItems = 8;

  Future<List<String>> load() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? [];
  }

  Future<void> save(List<String> history) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, history.take(_maxItems).toList());
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
