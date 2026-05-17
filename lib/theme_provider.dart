import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _mode;

  ThemeProvider(bool isDark) : _mode = isDark ? ThemeMode.dark : ThemeMode.light;

  ThemeMode get mode => _mode;
  bool get isDark => _mode == ThemeMode.dark;

  void toggle() {
    _mode = _mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    Hive.box('settings').put('darkMode', isDark);
    notifyListeners();
  }
}