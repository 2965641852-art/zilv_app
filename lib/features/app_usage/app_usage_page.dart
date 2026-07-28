import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zilv_app/features/app_usage/app_usage_provider.dart';

/// App 使用时长监控页
class AppUsagePage extends ConsumerStatefulWidget {
  const AppUsagePage({super.key});

  @override
  ConsumerState<AppUsagePage> createState() => _AppUsagePageState();
}

class _AppUsagePageState extends ConsumerState<AppUsagePage> {
  @override
  void initState() {
    super.initState();
    // 页面加载时自动获取数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(appUsageProvider.notifier).loadTodayStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appUsageProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('App 使用统计'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(appUsageProvider.notifier).loadTodayStats(),
          ),
        ],
      ),
      body: _buildBody(context, state, theme),
    );
  }

  Widget _buildBody(
      BuildContext context, AppUsageState state, ThemeData theme) {
    if (!state.isPermissionGranted) {
      return _buildPermissionPrompt(context, theme);
    }

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.apps.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.smartphone_outlined,
                size: 80, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text('暂无数据',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                )),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () =>
                  ref.read(appUsageProvider.notifier).loadTodayStats(),
              child: const Text('刷新'),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 今日总览
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text('今日屏幕使用时间',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    )),
                const SizedBox(height: 8),
                Text(
                  _formatDuration(state.totalSeconds),
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // 使用占比饼图
        if (state.apps.isNotEmpty) ...[
          Text('使用占比',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.primary,
              )),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                height: 200,
                child: _buildPieChart(context, state),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],

        // App 使用排行
        Text('使用排行',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.primary,
            )),
        const SizedBox(height: 8),
        ...state.apps.asMap().entries.map((entry) {
          final index = entry.key;
          final app = entry.value;
          final percentage = state.totalSeconds > 0
              ? (app.totalSeconds / state.totalSeconds * 100)
              : 0.0;

          return Card(
            margin: const EdgeInsets.only(bottom: 4),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: _getColor(index).withAlpha(30),
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: _getColor(index),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(app.appName),
              subtitle: Text(
                  '${_formatDuration(app.totalSeconds)}（${percentage.toStringAsFixed(1)}%）'),
              trailing: Icon(Icons.chevron_right,
                  color: theme.colorScheme.outline),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildPermissionPrompt(BuildContext context, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.admin_panel_settings_outlined,
                size: 80, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text('需要开启权限',
                style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              '为了监控各 App 使用时长，\n需要开启「使用情况访问权限」。\n\n点击下方按钮后，找到「自律助手」并开启权限。',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                ref.read(appUsageProvider.notifier).openPermissionSettings();
              },
              icon: const Icon(Icons.settings),
              label: const Text('去开启权限'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () async {
                await ref.read(appUsageProvider.notifier).checkPermission();
                if (mounted && ref.read(appUsageProvider).isPermissionGranted) {
                  ref.read(appUsageProvider.notifier).loadTodayStats();
                }
              },
              child: const Text('我已开启，检查权限'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChart(BuildContext context, AppUsageState state) {
    final colors = [
      Theme.of(context).colorScheme.primary,
      Theme.of(context).colorScheme.tertiary,
      Theme.of(context).colorScheme.error,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.blue,
      Colors.pink,
    ];

    // 取前8个，合并其余的为"其他"
    final topApps = state.apps.take(8).toList();
    final otherSeconds = state.apps.skip(8).fold(0, (sum, app) => sum + app.totalSeconds);

    final sections = <PieChartSectionData>[];
    for (var i = 0; i < topApps.length; i++) {
      final percentage = (topApps[i].totalSeconds / state.totalSeconds * 100);
      sections.add(PieChartSectionData(
        value: percentage,
        color: colors[i % colors.length],
        title: '${percentage.toStringAsFixed(0)}%',
        titleStyle: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
        radius: 80,
      ));
    }
    if (otherSeconds > 0) {
      final otherPct = (otherSeconds / state.totalSeconds * 100);
      sections.add(PieChartSectionData(
        value: otherPct,
        color: Colors.grey,
        title: '${otherPct.toStringAsFixed(0)}%',
        titleStyle: const TextStyle(fontSize: 11, color: Colors.white),
        radius: 80,
      ));
    }

    return PieChart(
      PieChartData(
        sections: sections,
        centerSpaceRadius: 30,
        sectionsSpace: 2,
      ),
    );
  }

  Color _getColor(int index) {
    const colors = [
      Colors.green,
      Colors.blue,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.cyan,
    ];
    return colors[index % colors.length];
  }

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h > 0) return '$h小时$m分钟';
    return '$m分钟';
  }
}
