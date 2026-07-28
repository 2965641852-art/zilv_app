import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:zilv_app/providers/database_provider.dart';

/// 统计页面 Provider
final statsDataProvider = FutureProvider<Map<String, int>>((ref) async {
  final dao = ref.watch(timeRecordDaoProvider);
  return dao.getLast7DaysSeconds();
});

final todayTotalProvider = FutureProvider<int>((ref) async {
  final dao = ref.watch(timeRecordDaoProvider);
  return dao.getTotalSecondsByDate(DateTime.now());
});

/// 统计页面
class StatsPage extends ConsumerWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayTotalAsync = ref.watch(todayTotalProvider);
    final weekDataAsync = ref.watch(statsDataProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('统计'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(todayTotalProvider);
          ref.invalidate(statsDataProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 今日概览卡片
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text('今日专注',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        )),
                    const SizedBox(height: 8),
                    todayTotalAsync.when(
                      data: (seconds) => Text(
                        _formatDuration(seconds),
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      loading: () => const CircularProgressIndicator(),
                      error: (_, _) => const Text('--:--'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 近7天趋势
            Text('近7天趋势',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                )),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: SizedBox(
                  height: 220,
                  child: weekDataAsync.when(
                    data: (data) => _buildBarChart(context, data),
                    loading: () => const Center(
                        child: CircularProgressIndicator()),
                    error: (_, _) => const Center(
                        child: Text('暂无数据')),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 本周总计
            _buildWeekTotal(ref, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart(BuildContext context, Map<String, int> data) {
    if (data.isEmpty) {
      return const Center(child: Text('暂无数据'));
    }

    final entries = data.entries.toList();
    final maxVal = entries.map((e) => e.value).reduce(max).toDouble();
    final maxY = maxVal <= 0 ? 60.0 : maxVal * 1.2;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        minY: 0,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final entry = entries[group.x.toInt()];
              return BarTooltipItem(
                '${entry.key}\n${_formatDuration(entry.value)}',
                const TextStyle(color: Colors.white, fontSize: 12),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= entries.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    entries[index].key,
                    style: const TextStyle(fontSize: 11),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const SizedBox.shrink();
                return Text(
                  _formatShortDuration(value.toInt()),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 4,
        ),
        borderData: FlBorderData(show: false),
        barGroups: entries.asMap().entries.map((e) {
          return BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: e.value.value.toDouble(),
                color: Theme.of(context).colorScheme.primary,
                width: 28,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(6),
                  topRight: Radius.circular(6),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildWeekTotal(WidgetRef ref, ThemeData theme) {
    return Card(
      child: FutureBuilder<int>(
        future: ref.read(timeRecordDaoProvider).getWeekTotalSeconds(),
        builder: (context, snapshot) {
          final seconds = snapshot.data ?? 0;
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text('本周累计',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    )),
                const SizedBox(height: 8),
                Text(
                  _formatDuration(seconds),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h > 0) {
      return '$h小时$m分钟';
    }
    return '$m分钟';
  }

  String _formatShortDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h > 0) return '${h}h';
    return '${m}m';
  }
}
