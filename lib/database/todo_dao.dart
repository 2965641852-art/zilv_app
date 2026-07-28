import 'package:sqflite/sqflite.dart';
import 'package:zilv_app/database/database.dart';
import 'package:zilv_app/database/models/todo_item.dart';

/// 待办事项数据访问对象
class TodoDao {
  final AppDatabase _db = AppDatabase();
  Database? _cachedDb;

  Future<Database> get _dbInstance async {
    _cachedDb ??= await _db.database;
    return _cachedDb!;
  }

  /// 获取所有待办
  Future<List<TodoItem>> getAll() async {
    final db = await _dbInstance;
    final maps = await db.query('todo_items', orderBy: 'created_at DESC');
    return maps.map((m) => TodoItem.fromMap(m)).toList();
  }

  /// 按日期范围获取待办
  Future<List<TodoItem>> getByDateRange(DateTime start, DateTime end) async {
    final db = await _dbInstance;
    final maps = await db.query(
      'todo_items',
      where: 'due_date >= ? AND due_date <= ?',
      whereArgs: [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
      orderBy: 'due_date ASC',
    );
    return maps.map((m) => TodoItem.fromMap(m)).toList();
  }

  /// 获取今日待办
  Future<List<TodoItem>> getToday() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(hours: 23, minutes: 59, seconds: 59));
    return getByDateRange(startOfDay, endOfDay);
  }

  /// 获取未完成的待办
  Future<List<TodoItem>> getPending() async {
    final db = await _dbInstance;
    final maps = await db.query(
      'todo_items',
      where: 'is_completed = 0',
      orderBy: 'priority DESC, due_date ASC',
    );
    return maps.map((m) => TodoItem.fromMap(m)).toList();
  }

  /// 根据ID获取待办
  Future<TodoItem?> getById(String id) async {
    final db = await _dbInstance;
    final maps = await db.query('todo_items', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return TodoItem.fromMap(maps.first);
  }

  /// 新增待办
  Future<void> insert(TodoItem item) async {
    final db = await _dbInstance;
    await db.insert('todo_items', item.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// 更新待办
  Future<void> update(TodoItem item) async {
    final db = await _dbInstance;
    await db.update(
      'todo_items',
      item.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  /// 切换完成状态
  Future<void> toggleComplete(String id) async {
    final db = await _dbInstance;
    final item = await getById(id);
    if (item == null) return;
    await db.update(
      'todo_items',
      {
        'is_completed': item.isCompleted ? 0 : 1,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 更新专注时长
  Future<void> addSeconds(String id, int seconds) async {
    final db = await _dbInstance;
    final item = await getById(id);
    if (item == null) return;
    await db.update(
      'todo_items',
      {
        'total_seconds': item.totalSeconds + seconds,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 删除待办
  Future<void> delete(String id) async {
    final db = await _dbInstance;
    await db.delete('todo_items', where: 'id = ?', whereArgs: [id]);
  }
}
