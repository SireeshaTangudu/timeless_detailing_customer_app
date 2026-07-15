import 'package:flutter/material.dart';
import 'package:timeless_detailing_customer_app/core/theme/app_theme.dart';

class ThemeController extends ChangeNotifier {
  bool _isDark = true;
  bool get isDark => _isDark;

  ThemeMode get themeMode => _isDark ? ThemeMode.dark : ThemeMode.light;

  ThemeController() {
    AppTheme.isDark = _isDark;
  }

  void toggleTheme() {
    _isDark = !_isDark;
    AppTheme.isDark = _isDark;
    notifyListeners();
  }
  
  void setDarkTheme(bool isDarkVal) {
    _isDark = isDarkVal;
    AppTheme.isDark = _isDark;
    notifyListeners();
  }
}
