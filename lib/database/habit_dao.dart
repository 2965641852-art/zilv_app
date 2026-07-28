import 'package:sqflite/sqflite.dart';
import 'package:zilv_app/database/database.dart';
import 'package:zilv_app/database/models/habit.dart';

/// 习惯数据访问对象
class HabitDao {
  final AppDatabase _db = AppDatabase();
  Database? _cachedDb;

  Future<Database> get _dbInstance async {
    _cachedDb ??= await _db.database;
    return _cachedDb!;
  }

  /// 获取数据库实例（供外部使用）
  Future<Database> getDb() async => _dbInstance;

  /// 获取所有习惯
  Future<List<Habit>> getAll() async {
    final db = await _dbInstance;
    final maps = await db.query('habits', orderBy: 'created_at DESC');
    return maps.map((m) => Habit.fromMap(m)).toList();
  }

  /// 获取单个习惯
  Future<Habit?> getById(String id) async {
    final db = await _dbInstance;
    final maps = await db.query('habits', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Habit.fromMap(maps.first);
  }

  /// 新增习惯
  Future<void> insert(Habit habit) async {
    final db = await _dbInstance;
    await db.insert('habits', habit.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// 更新习惯
  Future<void> update(Habit habit) async {
    final db = await _dbInstance;
    await db.update('habits', habit.toMap(),
        where: 'id = ?', whereArgs: [habit.id]);
  }

  /// 删除习惯
  Future<void> delete(String id) async {
    final db = await _dbInstance;
    await db.delete('habits', where: 'id = ?', whereArgs: [id]);
    // 同时删除关联的打卡记录
    await db.delete('habit_records', where: 'habit_id = ?', whereArgs: [id]);
  }

  // ========== 打卡记录 ==========

  /// 获取某习惯的打卡记录
  Future<List<HabitRecord>> getRecords(String habitId) async {
    final db = await _dbInstance;
    final maps = await db.query(
      'habit_records',
      where: 'habit_id = ?',
      whereArgs: [habitId],
      orderBy: 'date DESC',
    );
    return maps.map((m) => HabitRecord.fromMap(m)).toList();
  }

  /// 获取某习惯今天是否已打卡
  Future<HabitRecord?> getTodayRecord(String habitId) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(hours: 23, minutes: 59, seconds: 59));

    final db = await _dbInstance;
    final maps = await db.query(
      'habit_records',
      where: 'habit_id = ? AND date >= ? AND date <= ?',
      whereArgs: [
        habitId,
        startOfDay.millisecondsSinceEpoch,
        endOfDay.millisecondsSinceEpoch,
      ],
    );
    if (maps.isEmpty) return null;
    return HabitRecord.fromMap(maps.first);
  }

  /// 打卡
  Future<void> checkIn(HabitRecord record) async {
    final db = await _dbInstance;
    await db.insert('habit_records', record.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// 获取连续打卡天数
  Future<int> getStreakDays(String habitId) async {
    final records = await getRecords(habitId);
    if (records.isEmpty) return 0;

    // 按日期排序（从旧到新）
    records.sort((a, b) => a.date.compareTo(b.date));

    int streak = 0;
    final today = DateTime.now();
    var checkDate = DateTime(today.year, today.month, today.day);

    for (int i = records.length - 1; i >= 0; i--) {
      final recordDate = DateTime(
        records[i].date.year,
        records[i].date.month,
        records[i].date.day,
      );
      if (recordDate == checkDate) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else if (recordDate == checkDate.add(const Duration(days: 1))) {
        // 允许跳过今天（如果今天还没打卡）
        continue;
      } else {
        break;
      }
    }
    return streak;
  }
}
