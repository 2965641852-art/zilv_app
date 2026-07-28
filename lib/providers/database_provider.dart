import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zilv_app/database/todo_dao.dart';
import 'package:zilv_app/database/habit_dao.dart';
import 'package:zilv_app/database/time_record_dao.dart';

/// 数据库 DAO 提供者
final todoDaoProvider = Provider<TodoDao>((ref) => TodoDao());
final habitDaoProvider = Provider<HabitDao>((ref) => HabitDao());
final timeRecordDaoProvider = Provider<TimeRecordDao>((ref) => TimeRecordDao());
