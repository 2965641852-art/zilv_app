/// 习惯数据模型
class Habit {
  final String id;
  final String name;
  final String? description;
  final String frequency; // 'daily', 'weekly'
  final int targetCount; // 每日/周目标次数
  final DateTime createdAt;

  Habit({
    required this.id,
    required this.name,
    this.description,
    this.frequency = 'daily',
    this.targetCount = 1,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'description': description,
        'frequency': frequency,
        'target_count': targetCount,
        'created_at': createdAt.millisecondsSinceEpoch,
      };

  factory Habit.fromMap(Map<String, dynamic> map) => Habit(
        id: map['id'] as String,
        name: map['name'] as String,
        description: map['description'] as String?,
        frequency: map['frequency'] as String? ?? 'daily',
        targetCount: map['target_count'] as int? ?? 1,
        createdAt: DateTime.fromMillisecondsSinceEpoch(
            map['created_at'] as int),
      );

  Habit copyWith({
    String? id,
    String? name,
    String? description,
    String? frequency,
    int? targetCount,
  }) =>
      Habit(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        frequency: frequency ?? this.frequency,
        targetCount: targetCount ?? this.targetCount,
        createdAt: createdAt,
      );
}

/// 习惯打卡记录
class HabitRecord {
  final String id;
  final String habitId;
  final DateTime date;
  final int count;
  final DateTime createdAt;

  HabitRecord({
    required this.id,
    required this.habitId,
    required this.date,
    this.count = 1,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'habit_id': habitId,
        'date': date.millisecondsSinceEpoch,
        'count': count,
        'created_at': createdAt.millisecondsSinceEpoch,
      };

  factory HabitRecord.fromMap(Map<String, dynamic> map) => HabitRecord(
        id: map['id'] as String,
        habitId: map['habit_id'] as String,
        date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
        count: map['count'] as int? ?? 1,
        createdAt: DateTime.fromMillisecondsSinceEpoch(
            map['created_at'] as int),
      );
}
