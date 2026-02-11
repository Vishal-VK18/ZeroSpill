import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDark = false;

  bool get isDark => _isDark;

  ThemeMode get themeMode =>
      _isDark ? ThemeMode.dark : ThemeMode.light;

  void loadTheme(bool savedValue) {
    _isDark = savedValue;
  }

  void toggleTheme() {
    _isDark = !_isDark;
    notifyListeners();
  }
}
