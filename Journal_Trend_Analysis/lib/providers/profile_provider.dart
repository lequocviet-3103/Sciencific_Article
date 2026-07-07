import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tiny local-only profile. Tracks two numbers (first-open date and
/// searches run) so the Profile screen can show "X d active" / "Y
/// searches" without any networking. Everything else is just static
/// metadata and preferences.
class ProfileProvider extends ChangeNotifier {
  static const _kFirstOpen = 'profile_first_open_ms';
  static const _kSearchesRun = 'profile_searches_run';

  DateTime? _firstOpen;
  int _searchesRun = 0;

  DateTime? get firstOpen => _firstOpen;
  int get searchesRun => _searchesRun;

  /// Number of full days since the user installed / first opened
  /// the app. 0 on the first day.
  int get daysActive {
    final f = _firstOpen;
    if (f == null) return 0;
    return DateTime.now().difference(f).inDays;
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final firstMs = prefs.getInt(_kFirstOpen);
    if (firstMs != null) {
      _firstOpen = DateTime.fromMillisecondsSinceEpoch(firstMs);
    } else {
      _firstOpen = DateTime.now();
      await prefs.setInt(_kFirstOpen, _firstOpen!.millisecondsSinceEpoch);
    }
    _searchesRun = prefs.getInt(_kSearchesRun) ?? 0;
    notifyListeners();
  }

  Future<void> recordSearch() async {
    _searchesRun += 1;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kSearchesRun, _searchesRun);
  }

  Future<void> resetStats() async {
    _searchesRun = 0;
    _firstOpen = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kSearchesRun, 0);
    await prefs.setInt(_kFirstOpen, _firstOpen!.millisecondsSinceEpoch);
    notifyListeners();
  }
}
