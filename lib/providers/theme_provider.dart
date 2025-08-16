import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system; // Default to system theme

  ThemeMode get themeMode => _themeMode;

  ThemeProvider() {
    // Load the saved theme on startup
    _loadTheme();
  }

  /// Toggles between light and dark theme.
  void toggleTheme() async {
    _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    _saveTheme();
    notifyListeners(); // Notify widgets to rebuild
  }

  /// Sets the theme to a specific mode.
  void setTheme(ThemeMode mode) async {
    _themeMode = mode;
    _saveTheme();
    notifyListeners();
  }

  /// Saves the current theme mode to SharedPreferences.
  Future<void> _saveTheme() async {
    final prefs = await SharedPreferences.getInstance();
    // Saving as a string 'light', 'dark', or 'system'
    prefs.setString('themeMode', _themeMode.name);
  }

  /// Loads the theme from SharedPreferences.
  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString('themeMode');

    if (savedTheme != null) {
      if (savedTheme == 'light') {
        _themeMode = ThemeMode.light;
      } else if (savedTheme == 'dark') {
        _themeMode = ThemeMode.dark;
      } else {
        _themeMode = ThemeMode.system;
      }
    }
    notifyListeners();
  }
}