import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsController with ChangeNotifier {
  static const String _themeModeKey = 'themeMode';
  static const String _languageCodeKey = 'languageCode';
  static const String _hasSeenOnboardingKey = 'hasSeenOnboarding';

  ThemeMode _themeMode = ThemeMode.system;
  String? _languageCode;
  bool _hasSeenOnboarding = false;

  ThemeMode get themeMode => _themeMode;
  String? get languageCode => _languageCode;
  bool get hasSeenOnboarding => _hasSeenOnboarding;

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    final themeStr = prefs.getString(_themeModeKey);
    if (themeStr == 'light') {
      _themeMode = ThemeMode.light;
    } else if (themeStr == 'dark') {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.system;
    }

    _languageCode = prefs.getString(_languageCodeKey);
    _hasSeenOnboarding = prefs.getBool(_hasSeenOnboardingKey) ?? false;
    notifyListeners();
  }

  Future<void> updateThemeMode(ThemeMode? newThemeMode) async {
    if (newThemeMode == null || newThemeMode == _themeMode) return;

    _themeMode = newThemeMode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    if (newThemeMode == ThemeMode.light) {
      await prefs.setString(_themeModeKey, 'light');
    } else if (newThemeMode == ThemeMode.dark) {
      await prefs.setString(_themeModeKey, 'dark');
    } else {
      await prefs.setString(_themeModeKey, 'system');
    }
  }

  Future<void> updateLanguageCode(String? newLanguageCode) async {
    if (newLanguageCode == _languageCode) return;

    _languageCode = newLanguageCode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    if (newLanguageCode != null) {
      await prefs.setString(_languageCodeKey, newLanguageCode);
    } else {
      await prefs.remove(_languageCodeKey);
    }
  }

  Future<void> markOnboardingAsSeen() async {
    if (_hasSeenOnboarding) return;

    _hasSeenOnboarding = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasSeenOnboardingKey, true);
  }
}
