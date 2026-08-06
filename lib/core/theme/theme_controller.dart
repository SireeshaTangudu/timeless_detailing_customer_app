import 'package:flutter/material.dart';

class ThemeController extends ChangeNotifier {
  bool get isDark => false;

  ThemeMode get themeMode => ThemeMode.light;

  ThemeController();

  void toggleTheme() {
    notifyListeners();
  }

  void setDarkTheme(bool isDarkVal) {
    notifyListeners();
  }
}
