/// 计时记录数据模型
class TimeRecord {
  final String id;
  final String? todoId;
  final String title;
  final DateTime startTime;
  final DateTime? endTime;
  final int durationSeconds;
  final DateTime date;
  final DateTime createdAt;

  TimeRecord({
    required this.id,
    this.todoId,
    required this.title,
    required this.startTime,
    this.endTime,
    required this.durationSeconds,
    required this.date,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'todo_id': todoId,
        'title': title,
        'start_time': startTime.millisecondsSinceEpoch,
        'end_time': endTime?.millisecondsSinceEpoch,
        'duration_seconds': durationSeconds,
        'date': date.millisecondsSinceEpoch,
        'created_at': createdAt.millisecondsSinceEpoch,
      };

  factory TimeRecord.fromMap(Map<String, dynamic> map) => TimeRecord(
        id: map['id'] as String,
        todoId: map['todo_id'] as String?,
        title: map['title'] as String,
        startTime:
            DateTime.fromMillisecondsSinceEpoch(map['start_time'] as int),
        endTime: map['end_time'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['end_time'] as int)
            : null,
        durationSeconds: map['duration_seconds'] as int? ?? 0,
        date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
        createdAt: DateTime.fromMillisecondsSinceEpoch(
            map['created_at'] as int),
      );
}
