import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  final SharedPreferences sharedPreferences;
  static const String _themeKey = 'is_dark_mode';

  ThemeCubit({required this.sharedPreferences}) : super(ThemeMode.light) {
    _loadTheme();
  }

  void _loadTheme() {
    final isDark = sharedPreferences.getBool(_themeKey) ?? false;
    emit(isDark ? ThemeMode.dark : ThemeMode.light);
  }

  void toggleTheme(bool isDark) {
    sharedPreferences.setBool(_themeKey, isDark);
    emit(isDark ? ThemeMode.dark : ThemeMode.light);
  }
}
