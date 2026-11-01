import 'package:flutter/material.dart';

enum AppThemeMode { light, dark, system }

/// [ThemeService]
/// Mengelola status tema aplikasi RideOn Driver secara global dan reaktif.
/// Mendukung Mode Terang, Mode Gelap, dan Ikuti Sistem sesuai spesifikasi Figma:
/// - Figma/PengaturanAkun/mode terang.png
/// - Figma/PengaturanAkun/mode gelap.png
/// - Figma/PengaturanAkun/ikuti sistem.png
class ThemeService extends ChangeNotifier {
  static final ThemeService _instance = ThemeService._internal();
  factory ThemeService() => _instance;
  ThemeService._internal();

  AppThemeMode _currentTheme = AppThemeMode.system;

  AppThemeMode get currentTheme => _currentTheme;

  ThemeMode get themeMode {
    switch (_currentTheme) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }

  bool isDarkMode(BuildContext context) {
    if (_currentTheme == AppThemeMode.dark) return true;
    if (_currentTheme == AppThemeMode.light) return false;
    return MediaQuery.platformBrightnessOf(context) == Brightness.dark;
  }

  void setTheme(AppThemeMode mode) {
    if (_currentTheme != mode) {
      _currentTheme = mode;
      notifyListeners();
    }
  }

  /// Reset untuk keperluan unit testing
  @visibleForTesting
  void reset() {
    _currentTheme = AppThemeMode.system;
  }
}
