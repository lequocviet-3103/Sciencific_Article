import 'package:flutter/foundation.dart';

class AppConfig {
  static const int defaultPerPage = 30;
  static const int maxLoadedResults = 200;
  static const Duration httpTimeout = Duration(seconds: 35);

  /// Optional build-time override, useful for a physical phone or a backend
  /// running on another computer:
  ///
  /// flutter run --dart-define=API_BASE_URL=http://192.168.1.10:5255
  static const String _apiBaseUrlOverride = String.fromEnvironment(
    'API_BASE_URL',
  );

  /// Android Emulator reaches the Windows host through 10.0.2.2. Web keeps
  /// localhost so the project can still be opened for quick browser checks.
  static String get apiBaseUrl {
    if (_apiBaseUrlOverride.trim().isNotEmpty) {
      return _withoutTrailingSlash(_apiBaseUrlOverride.trim());
    }

    return kIsWeb ? 'http://localhost:5255' : 'http://10.0.2.2:5255';
  }

  static String _withoutTrailingSlash(String value) {
    return value.endsWith('/') ? value.substring(0, value.length - 1) : value;
  }
}
