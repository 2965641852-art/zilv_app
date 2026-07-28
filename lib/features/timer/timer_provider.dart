import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:zilv_app/database/models/time_record.dart';
import 'package:zilv_app/database/models/todo_item.dart';
import 'package:zilv_app/database/time_record_dao.dart';
import 'package:zilv_app/database/todo_dao.dart';
import 'package:zilv_app/providers/database_provider.dart';

/// 计时器状态
enum TimerStatus { idle, running, paused }

/// 计时器状态
class TimerState {
  final TimerStatus status;
  final int elapsedSeconds; // 已过秒数
  final TodoItem? linkedTodo; // 关联的待办
  final DateTime? startTime;

  const TimerState({
    this.status = TimerStatus.idle,
    this.elapsedSeconds = 0,
    this.linkedTodo,
    this.startTime,
  });

  String get formattedTime {
    final h = elapsedSeconds ~/ 3600;
    final m = (elapsedSeconds % 3600) ~/ 60;
    final s = elapsedSeconds % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  TimerState copyWith({
    TimerStatus? status,
    int? elapsedSeconds,
    TodoItem? linkedTodo,
    DateTime? startTime,
    bool clearTodo = false,
  }) =>
      TimerState(
        status: status ?? this.status,
        elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
        linkedTodo: clearTodo ? null : (linkedTodo ?? this.linkedTodo),
        startTime: startTime ?? this.startTime,
      );
}

/// 计时器 Provider
final timerProvider = StateNotifierProvider<TimerNotifier, TimerState>((ref) {
  final timeRecordDao = ref.watch(timeRecordDaoProvider);
  final todoDao = ref.watch(todoDaoProvider);
  return TimerNotifier(timeRecordDao, todoDao);
});

class TimerNotifier extends StateNotifier<TimerState> {
  final TimeRecordDao _timeRecordDao;
  final TodoDao _todoDao;
  Timer? _timer;

  TimerNotifier(this._timeRecordDao, this._todoDao) : super(const TimerState());

  /// 设置关联的待办
  void setLinkedTodo(TodoItem? todo) {
    if (state.status != TimerStatus.idle) return; // 计时中不允许切换
    state = state.copyWith(linkedTodo: todo, clearTodo: todo == null);
  }

  /// 开始计时
  void start() {
    if (state.status == TimerStatus.running) return;

    final startTime = state.status == TimerStatus.paused
        ? state.startTime
        : DateTime.now();

    state = state.copyWith(
      status: TimerStatus.running,
      startTime: startTime,
    );

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.startTime != null) {
        final elapsed = DateTime.now().difference(state.startTime!).inSeconds;
        state = state.copyWith(elapsedSeconds: elapsed);
      }
    });
  }

  /// 暂停计时
  void pause() {
    _timer?.cancel();
    state = state.copyWith(status: TimerStatus.paused);
  }

  /// 停止并保存记录
  Future<void> stop() async {
    _timer?.cancel();
    if (state.elapsedSeconds < 1) {
      state = const TimerState();
      return;
    }

    final now = DateTime.now();
    final record = TimeRecord(
      id: const Uuid().v4(),
      todoId: state.linkedTodo?.id,
      title: state.linkedTodo?.title ?? '专注时段',
      startTime: state.startTime ?? now,
      endTime: now,
      durationSeconds: state.elapsedSeconds,
      date: DateTime(now.year, now.month, now.day),
    );

    await _timeRecordDao.insert(record);

    // 如果有关联待办，更新其累计时长
    if (state.linkedTodo != null) {
      await _todoDao.addSeconds(state.linkedTodo!.id, state.elapsedSeconds);
    }

    state = const TimerState();
  }

  /// 重置
  void reset() {
    _timer?.cancel();
    state = const TimerState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
