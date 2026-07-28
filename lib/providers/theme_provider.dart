import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 主题模式
enum ThemeModeType { light, dark, system }

/// 主题状态管理
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeModeType>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeModeType> {
  ThemeModeNotifier() : super(ThemeModeType.system) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt('theme_mode') ?? 2;
    state = ThemeModeType.values[index];
  }

  Future<void> setTheme(ThemeModeType mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_mode', mode.index);
  }

  ThemeMode get themeMode {
    switch (state) {
      case ThemeModeType.light:
        return ThemeMode.light;
      case ThemeModeType.dark:
        return ThemeMode.dark;
      case ThemeModeType.system:
        return ThemeMode.system;
    }
  }
}
