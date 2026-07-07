import 'package:flutter/foundation.dart';

class AppConfig {
  static const int defaultPerPage = 30;
  static const int maxLoadedResults = 200;
  static const Duration httpTimeout = Duration(seconds: 35);

  // Web/desktop run in a normal browser/OS network stack and can hit the
  // backend directly via localhost. The Android emulator instead routes
  // 10.0.2.2 to the host machine's localhost, so it needs that alias.
  static final String apiBaseUrl =
      kIsWeb ? 'http://localhost:5255' : 'http://10.0.2.2:5255';
}
