import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zilv_app/app.dart';
import 'package:zilv_app/providers/theme_provider.dart';
import 'package:zilv_app/services/notification_service.dart';
import 'package:zilv_app/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().init();
  runApp(
    const ProviderScope(
      child: ZilvApp(),
    ),
  );
}

class ZilvApp extends ConsumerWidget {
  const ZilvApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeModeType = ref.watch(themeModeProvider);

    return MaterialApp(
      title: '自律助手',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _resolveThemeMode(themeModeType),
      home: const HomePage(),
    );
  }

  ThemeMode _resolveThemeMode(ThemeModeType type) {
    switch (type) {
      case ThemeModeType.light:
        return ThemeMode.light;
      case ThemeModeType.dark:
        return ThemeMode.dark;
      case ThemeModeType.system:
        return ThemeMode.system;
    }
  }
}
