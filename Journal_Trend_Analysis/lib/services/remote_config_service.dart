import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

class RemoteConfigService {
  RemoteConfigService() : _config = FirebaseRemoteConfig.instance;
  final FirebaseRemoteConfig _config;

  Future<void> initialize() async {
    await _config.setDefaults(<String, dynamic>{
      'app_version': '1.0.0',
      'min_app_version': '1.0.0',
      'maintenance_mode': false,
      'default_page_size': 30,
      'max_search_results': 200,
    });

    await _config.fetchAndActivate();
  }

  String get appVersion => _config.getString('app_version');
  String get minAppVersion => _config.getString('min_app_version');
  bool get maintenanceMode => _config.getBool('maintenance_mode');
  int get defaultPageSize => _config.getInt('default_page_size');
  int get maxSearchResults => _config.getInt('max_search_results');
}
