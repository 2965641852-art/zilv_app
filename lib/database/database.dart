import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// 数据库管理器（单例）
class AppDatabase {
  static final AppDatabase _instance = AppDatabase._internal();
  factory AppDatabase() => _instance;
  AppDatabase._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dir.path, 'zilv_app.db');
    return openDatabase(
      dbPath,
      version: 1,
      onCreate: _createTables,
    );
  }

  Future<void> _createTables(Database db, int version) async {
    // 待办事项表
    await db.execute('''
      CREATE TABLE todo_items (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        due_date INTEGER,
        priority INTEGER DEFAULT 0,
        is_completed INTEGER DEFAULT 0,
        total_seconds INTEGER DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // 习惯表
    await db.execute('''
      CREATE TABLE habits (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        frequency TEXT DEFAULT 'daily',
        target_count INTEGER DEFAULT 1,
        created_at INTEGER NOT NULL
      )
    ''');

    // 习惯打卡记录表
    await db.execute('''
      CREATE TABLE habit_records (
        id TEXT PRIMARY KEY,
        habit_id TEXT NOT NULL,
        date INTEGER NOT NULL,
        count INTEGER DEFAULT 1,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (habit_id) REFERENCES habits(id)
      )
    ''');

    // 计时记录表
    await db.execute('''
      CREATE TABLE time_records (
        id TEXT PRIMARY KEY,
        todo_id TEXT,
        title TEXT NOT NULL,
        start_time INTEGER NOT NULL,
        end_time INTEGER,
        duration_seconds INTEGER NOT NULL,
        date INTEGER NOT NULL,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (todo_id) REFERENCES todo_items(id)
      )
    ''');

    // 索引
    await db.execute('CREATE INDEX idx_todo_due_date ON todo_items(due_date)');
    await db.execute('CREATE INDEX idx_todo_completed ON todo_items(is_completed)');
    await db.execute('CREATE INDEX idx_habit_record_date ON habit_records(date)');
    await db.execute('CREATE INDEX idx_habit_record_habit ON habit_records(habit_id)');
    await db.execute('CREATE INDEX idx_time_record_date ON time_records(date)');
  }
}
