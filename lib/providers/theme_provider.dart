import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider para gestionar el tema de la aplicación (claro/oscuro)
class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'app_theme_mode';

  ThemeMode _themeMode = ThemeMode.system; // Usar tema del sistema por defecto
  SharedPreferences? _prefs;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  /// Inicializar el provider y cargar preferencia guardada
  Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      _loadThemeMode();
    } catch (e) {
      debugPrint('⚠️ Error initializing ThemeProvider: $e');
      debugPrint('   Using default theme (system mode)');
      _themeMode = ThemeMode.system;
    }
  }

  /// Cargar el modo de tema desde SharedPreferences
  void _loadThemeMode() {
    if (_prefs == null) {
      _themeMode = ThemeMode.system; // Usar tema del sistema por defecto
      return;
    }

    final savedTheme = _prefs!.getString(_themeKey);

    if (savedTheme == null) {
      // Usar tema del sistema si no hay preferencia guardada
      _themeMode = ThemeMode.system;
    } else if (savedTheme == 'dark') {
      _themeMode = ThemeMode.dark;
    } else if (savedTheme == 'light') {
      _themeMode = ThemeMode.light;
    } else if (savedTheme == 'system') {
      _themeMode = ThemeMode.system;
    } else {
      _themeMode = ThemeMode.system; // Fallback al sistema
    }

    notifyListeners();
  }

  /// Cambiar entre tema claro y oscuro
  Future<void> toggleTheme() async {
    if (_themeMode == ThemeMode.dark) {
      _themeMode = ThemeMode.light;
      if (_prefs != null) {
        await _prefs!.setString(_themeKey, 'light');
      }
    } else {
      _themeMode = ThemeMode.dark;
      if (_prefs != null) {
        await _prefs!.setString(_themeKey, 'dark');
      }
    }

    notifyListeners();
  }

  /// Establecer tema específico
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;

    if (_prefs != null) {
      switch (mode) {
        case ThemeMode.dark:
          await _prefs!.setString(_themeKey, 'dark');
          break;
        case ThemeMode.light:
          await _prefs!.setString(_themeKey, 'light');
          break;
        case ThemeMode.system:
          await _prefs!.setString(_themeKey, 'system');
          break;
      }
    }

    notifyListeners();
  }
}
