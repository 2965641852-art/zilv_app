import 'package:sqflite/sqflite.dart';
import 'package:zilv_app/database/database.dart';
import 'package:zilv_app/database/models/time_record.dart';

/// 计时记录数据访问对象
class TimeRecordDao {
  final AppDatabase _db = AppDatabase();
  Database? _cachedDb;

  Future<Database> get _dbInstance async {
    _cachedDb ??= await _db.database;
    return _cachedDb!;
  }

  /// 新增记录
  Future<void> insert(TimeRecord record) async {
    final db = await _dbInstance;
    await db.insert('time_records', record.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// 获取某天的所有记录
  Future<List<TimeRecord>> getByDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(hours: 23, minutes: 59, seconds: 59));

    final db = await _dbInstance;
    final maps = await db.query(
      'time_records',
      where: 'date >= ? AND date <= ?',
      whereArgs: [startOfDay.millisecondsSinceEpoch, endOfDay.millisecondsSinceEpoch],
      orderBy: 'start_time DESC',
    );
    return maps.map((m) => TimeRecord.fromMap(m)).toList();
  }

  /// 获取日期范围内的记录
  Future<List<TimeRecord>> getByDateRange(DateTime start, DateTime end) async {
    final db = await _dbInstance;
    final maps = await db.query(
      'time_records',
      where: 'date >= ? AND date <= ?',
      whereArgs: [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
      orderBy: 'start_time DESC',
    );
    return maps.map((m) => TimeRecord.fromMap(m)).toList();
  }

  /// 获取某天的总专注秒数
  Future<int> getTotalSecondsByDate(DateTime date) async {
    final records = await getByDate(date);
    return records.fold<int>(0, (sum, r) => sum + r.durationSeconds);
  }

  /// 获取某天按待办分组的专注时长
  Future<Map<String?, int>> getSecondsGroupedByTodo(DateTime date) async {
    final records = await getByDate(date);
    final result = <String?, int>{};
    for (final r in records) {
      result[r.todoId] = (result[r.todoId] ?? 0) + r.durationSeconds;
    }
    return result;
  }

  /// 获取本周总时长
  Future<int> getWeekTotalSeconds() async {
    final now = DateTime.now();
    final weekday = now.weekday;
    final startOfWeek = DateTime(now.year, now.month, now.day - weekday + 1);
    final endOfWeek = startOfWeek.add(const Duration(days: 7));

    final records = await getByDateRange(startOfWeek, endOfWeek);
    return records.fold<int>(0, (sum, r) => sum + r.durationSeconds);
  }

  /// 获取最近7天的每日时长
  Future<Map<String, int>> getLast7DaysSeconds() async {
    final result = <String, int>{};
    final now = DateTime.now();
    for (int i = 6; i >= 0; i--) {
      final date = DateTime(now.year, now.month, now.day - i);
      final key = '${date.month}/${date.day}';
      result[key] = await getTotalSecondsByDate(date);
    }
    return result;
  }
}
