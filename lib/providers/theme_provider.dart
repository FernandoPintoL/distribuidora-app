import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider para gestionar el tema de la aplicación (claro/oscuro)
class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'app_theme_mode';

  ThemeMode _themeMode = ThemeMode.light;
  late SharedPreferences _prefs;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  /// Inicializar el provider y cargar preferencia guardada
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _loadThemeMode();
  }

  /// Cargar el modo de tema desde SharedPreferences
  void _loadThemeMode() {
    final savedTheme = _prefs.getString(_themeKey);

    if (savedTheme == null) {
      // Usar tema del sistema si no hay preferencia guardada
      _themeMode = ThemeMode.system;
    } else if (savedTheme == 'dark') {
      _themeMode = ThemeMode.dark;
    } else if (savedTheme == 'light') {
      _themeMode = ThemeMode.light;
    } else {
      _themeMode = ThemeMode.system;
    }

    notifyListeners();
  }

  /// Cambiar entre tema claro y oscuro
  Future<void> toggleTheme() async {
    if (_themeMode == ThemeMode.dark) {
      _themeMode = ThemeMode.light;
      await _prefs.setString(_themeKey, 'light');
    } else {
      _themeMode = ThemeMode.dark;
      await _prefs.setString(_themeKey, 'dark');
    }

    notifyListeners();
  }

  /// Establecer tema específico
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;

    switch (mode) {
      case ThemeMode.dark:
        await _prefs.setString(_themeKey, 'dark');
        break;
      case ThemeMode.light:
        await _prefs.setString(_themeKey, 'light');
        break;
      case ThemeMode.system:
        await _prefs.remove(_themeKey);
        break;
    }

    notifyListeners();
  }
}
