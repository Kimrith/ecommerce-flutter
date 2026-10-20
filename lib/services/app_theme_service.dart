import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppThemeService {
  static const String _themeKey = 'app_theme_mode';
  static final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier(ThemeMode.light);

  /// Load theme preference from SharedPreferences
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool(_themeKey) ?? false;
    themeModeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  /// Toggle theme between Light and Dark mode, saving to SharedPreferences
  static Future<void> toggleTheme([bool? isDark]) async {
    final prefs = await SharedPreferences.getInstance();
    final newMode = isDark != null
        ? (isDark ? ThemeMode.dark : ThemeMode.light)
        : (themeModeNotifier.value == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
    themeModeNotifier.value = newMode;
    await prefs.setBool(_themeKey, newMode == ThemeMode.dark);
  }

  static bool get isDarkMode => themeModeNotifier.value == ThemeMode.dark;
}
