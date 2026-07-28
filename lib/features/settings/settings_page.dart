import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zilv_app/providers/theme_provider.dart';
import 'package:zilv_app/services/notification_service.dart';

/// 设置页面
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 外观设置
          Text('外观', style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.primary,
          )),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.brightness_6),
                  title: const Text('主题模式'),
                  subtitle: Text(_themeModeLabel(themeMode)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showThemePicker(context, ref),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 通知设置
          Text('通知', style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.primary,
          )),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.notifications_outlined),
                  title: const Text('通知权限'),
                  subtitle: const Text('管理待办和习惯提醒'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _requestNotification(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 关于
          Text('关于', style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.primary,
          )),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('版本'),
                  subtitle: const Text('v1.0.0'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _themeModeLabel(ThemeModeType mode) {
    switch (mode) {
      case ThemeModeType.light:
        return '浅色';
      case ThemeModeType.dark:
        return '深色';
      case ThemeModeType.system:
        return '跟随系统';
    }
  }

  void _requestNotification(BuildContext context) async {
    final service = NotificationService();
    await service.requestPermissions();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('通知权限已开启')),
      );
    }
  }

  void _showThemePicker(BuildContext context, WidgetRef ref) {
    final current = ref.read(themeModeProvider);
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('选择主题模式'),
        children: [
          RadioGroup<ThemeModeType>(
            groupValue: current,
            onChanged: (value) {
              if (value != null) {
                ref.read(themeModeProvider.notifier).setTheme(value);
                Navigator.pop(ctx);
              }
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: ThemeModeType.values.map((mode) {
                return RadioListTile<ThemeModeType>(
                  title: Text(_themeModeLabel(mode)),
                  value: mode,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
