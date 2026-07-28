import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// App 使用数据模型
class AppUsageInfo {
  final String packageName;
  final String appName;
  final int totalSeconds; // 前台使用时长（秒）

  AppUsageInfo({
    required this.packageName,
    required this.appName,
    required this.totalSeconds,
  });

  factory AppUsageInfo.fromMap(Map<String, dynamic> map) => AppUsageInfo(
        packageName: map['packageName'] as String,
        appName: map['appName'] as String,
        totalSeconds: map['totalTimeInForeground'] as int,
      );
}

/// App 使用统计状态
class AppUsageState {
  final List<AppUsageInfo> apps;
  final bool isPermissionGranted;
  final bool isLoading;

  const AppUsageState({
    this.apps = const [],
    this.isPermissionGranted = false,
    this.isLoading = false,
  });

  int get totalSeconds =>
      apps.fold(0, (sum, app) => sum + app.totalSeconds);

  AppUsageState copyWith({
    List<AppUsageInfo>? apps,
    bool? isPermissionGranted,
    bool? isLoading,
  }) =>
      AppUsageState(
        apps: apps ?? this.apps,
        isPermissionGranted: isPermissionGranted ?? this.isPermissionGranted,
        isLoading: isLoading ?? this.isLoading,
      );
}

/// Method Channel
const _channel = MethodChannel('com.zilv.zilv_app/usage_stats');

/// App 使用统计 Provider
final appUsageProvider =
    StateNotifierProvider<AppUsageNotifier, AppUsageState>((ref) {
  return AppUsageNotifier();
});

class AppUsageNotifier extends StateNotifier<AppUsageState> {
  AppUsageNotifier() : super(const AppUsageState()) {
    checkPermission();
  }

  /// 检查权限
  Future<bool> checkPermission() async {
    try {
      final granted = await _channel.invokeMethod<bool>('isPermissionGranted');
      state = state.copyWith(isPermissionGranted: granted ?? false);
      return granted ?? false;
    } catch (e) {
      state = state.copyWith(isPermissionGranted: false);
      return false;
    }
  }

  /// 打开权限设置
  Future<void> openPermissionSettings() async {
    try {
      await _channel.invokeMethod('openPermissionSettings');
    } catch (_) {}
  }

  /// 加载使用数据
  Future<void> loadTodayStats() async {
    state = state.copyWith(isLoading: true);

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    try {
      final result = await _channel.invokeMethod<List<dynamic>>(
        'getAppUsageStats',
        {
          'startTime': startOfDay.millisecondsSinceEpoch,
          'endTime': endOfDay.millisecondsSinceEpoch,
        },
      );

      final apps = (result as List)
          .map((e) => AppUsageInfo.fromMap(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.totalSeconds.compareTo(a.totalSeconds));

      state = AppUsageState(
        apps: apps,
        isPermissionGranted: state.isPermissionGranted,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }
}
