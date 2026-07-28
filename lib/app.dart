import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zilv_app/features/todos/todo_list_page.dart';
import 'package:zilv_app/features/habits/habit_list_page.dart';
import 'package:zilv_app/features/timer/timer_page.dart';
import 'package:zilv_app/features/stats/stats_page.dart';
import 'package:zilv_app/features/app_usage/app_usage_page.dart';
import 'package:zilv_app/features/settings/settings_page.dart';

/// 底部标签页索引
final currentTabProvider = StateProvider<int>((ref) => 0);

/// 主页 — 底部导航框架
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  static const _pages = <Widget>[
    TodoListPage(),
    HabitListPage(),
    TimerPage(),
    StatsPage(),
    AppUsagePage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTab = ref.watch(currentTabProvider);

    return Scaffold(
      body: IndexedStack(
        index: currentTab,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentTab,
        onDestinationSelected: (index) {
          ref.read(currentTabProvider.notifier).state = index;
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.checklist_outlined),
            selectedIcon: Icon(Icons.checklist),
            label: '待办',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite),
            label: '习惯',
          ),
          NavigationDestination(
            icon: Icon(Icons.timer_outlined),
            selectedIcon: Icon(Icons.timer),
            label: '专注',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: '统计',
          ),
          NavigationDestination(
            icon: Icon(Icons.phone_android_outlined),
            selectedIcon: Icon(Icons.phone_android),
            label: '手机',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: '设置',
          ),
        ],
      ),
    );
  }
}
