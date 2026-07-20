import 'package:flutter/foundation.dart';

import '../services/remote_config_service.dart';

class RemoteConfigProvider extends ChangeNotifier {
  RemoteConfigProvider({RemoteConfigService? service})
    : _service = service ?? RemoteConfigService.instance;

  final RemoteConfigService _service;
  bool _isReady = false;

  bool get isReady => _isReady;
  bool get enableExport => _service.enableExport;
  bool get maintenanceMode => _service.maintenanceMode;
  String get latestTopic => _service.latestTopic;
  int get maxSearchResults => _service.maxSearchResults;

  Future<void> initialize() async {
    await _service.initialize();
    _isReady = true;
    notifyListeners();
  }
}
