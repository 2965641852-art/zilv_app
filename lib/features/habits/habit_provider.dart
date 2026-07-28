import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:zilv_app/database/habit_dao.dart';
import 'package:zilv_app/database/models/habit.dart';
import 'package:zilv_app/providers/database_provider.dart';

/// 习惯列表状态
class HabitListState {
  final List<Habit> habits;
  final Map<String, bool> todayChecked; // habitId -> 是否已打卡
  final Map<String, int> streakDays; // habitId -> 连续天数
  final bool isLoading;

  const HabitListState({
    this.habits = const [],
    this.todayChecked = const {},
    this.streakDays = const {},
    this.isLoading = false,
  });

  HabitListState copyWith({
    List<Habit>? habits,
    Map<String, bool>? todayChecked,
    Map<String, int>? streakDays,
    bool? isLoading,
  }) =>
      HabitListState(
        habits: habits ?? this.habits,
        todayChecked: todayChecked ?? this.todayChecked,
        streakDays: streakDays ?? this.streakDays,
        isLoading: isLoading ?? this.isLoading,
      );
}

/// 习惯列表 Provider
final habitListProvider =
    StateNotifierProvider<HabitListNotifier, HabitListState>((ref) {
  final dao = ref.watch(habitDaoProvider);
  return HabitListNotifier(dao);
});

class HabitListNotifier extends StateNotifier<HabitListState> {
  final HabitDao _dao;

  HabitListNotifier(this._dao) : super(const HabitListState()) {
    loadAll();
  }

  Future<void> loadAll() async {
    state = state.copyWith(isLoading: true);
    final habits = await _dao.getAll();
    final todayChecked = <String, bool>{};
    final streakDays = <String, int>{};

    for (final habit in habits) {
      final record = await _dao.getTodayRecord(habit.id);
      todayChecked[habit.id] = record != null;
      streakDays[habit.id] = await _dao.getStreakDays(habit.id);
    }

    state = HabitListState(
      habits: habits,
      todayChecked: todayChecked,
      streakDays: streakDays,
    );
  }

  Future<void> add(String name, String? description, String frequency) async {
    final habit = Habit(
      id: const Uuid().v4(),
      name: name,
      description: description,
      frequency: frequency,
    );
    await _dao.insert(habit);
    await loadAll();
  }

  Future<void> delete(String id) async {
    await _dao.delete(id);
    await loadAll();
  }

  /// 打卡/取消打卡
  Future<void> toggleCheckIn(String habitId) async {
    final existing = await _dao.getTodayRecord(habitId);
    if (existing != null) {
      // 已打卡 -> 取消
      final db = await _dao.getDb();
      await db.delete('habit_records',
          where: 'id = ?', whereArgs: [existing.id]);
    } else {
      // 未打卡 -> 打卡
      final record = HabitRecord(
        id: const Uuid().v4(),
        habitId: habitId,
        date: DateTime.now(),
      );
      await _dao.checkIn(record);
    }
    await loadAll();
  }
}
