import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeProvider({bool? isDark}) : _isDark = isDark ?? false;

  bool _isDark;
  bool get isDark => _isDark;

  ThemeMode get themeMode => _isDark ? ThemeMode.dark : ThemeMode.light;

  void toggle() {
    _isDark = !_isDark;
    notifyListeners();
  }
}
