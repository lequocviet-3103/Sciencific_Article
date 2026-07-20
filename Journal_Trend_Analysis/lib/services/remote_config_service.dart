import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

class RemoteConfigService {
  RemoteConfigService._() : _config = FirebaseRemoteConfig.instance;

  static final RemoteConfigService instance = RemoteConfigService._();
  final FirebaseRemoteConfig _config;

  Future<void> initialize() async {
    try {
      await _config.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: kDebugMode
              ? Duration.zero
              : const Duration(hours: 1),
        ),
      );
      await _config.setDefaults(<String, dynamic>{
        'app_version': '1.0.0',
        'min_app_version': '1.0.0',
        'enable_export': true,
        'maintenance_mode': false,
        'latest_topic': 'Artificial Intelligence',
        'default_page_size': 20,
        'max_search_results': 20,
      });
      await _config.fetchAndActivate();
    } catch (error) {
      // Defaults remain active when the device is offline or Firebase has not
      // been configured in the Console yet.
      debugPrint('[RemoteConfig] fetch failed; using defaults: $error');
    }
  }

  String get appVersion => _config.getString('app_version');
  String get minAppVersion => _config.getString('min_app_version');
  bool get maintenanceMode => _config.getBool('maintenance_mode');
  bool get enableExport => _config.getBool('enable_export');
  String get latestTopic {
    final value = _config.getString('latest_topic').trim();
    return value.isEmpty ? 'Artificial Intelligence' : value;
  }

  int get defaultPageSize => _config.getInt('default_page_size');
  int get maxSearchResults {
    final value = _config.getInt('max_search_results');
    // Guard accidental Console values such as 0 or 1: those make the API
    // total say "23 publications" while the dashboard/list receives only
    // one item. The supported UI range is intentionally bounded.
    return value >= 10 && value <= 200 ? value : 20;
  }
}
