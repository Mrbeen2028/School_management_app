import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  // Explicitly set dark mode on or off
  void setDarkMode(bool value) {
    if (_isDarkMode != value) {
      _isDarkMode = value;
      notifyListeners();
    }
  }

  // Optional: toggle dark mode on/off
  void toggleTheme(bool val) {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }
}
