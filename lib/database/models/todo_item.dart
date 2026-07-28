/// 待办事项数据模型
class TodoItem {
  final String id;
  final String title;
  final String? description;
  final DateTime? dueDate;
  final int priority; // 0=普通, 1=重要
  final bool isCompleted;
  final int totalSeconds; // 累计专注秒数
  final DateTime createdAt;
  final DateTime updatedAt;

  TodoItem({
    required this.id,
    required this.title,
    this.description,
    this.dueDate,
    this.priority = 0,
    this.isCompleted = false,
    this.totalSeconds = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'due_date': dueDate?.millisecondsSinceEpoch,
        'priority': priority,
        'is_completed': isCompleted ? 1 : 0,
        'total_seconds': totalSeconds,
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
      };

  factory TodoItem.fromMap(Map<String, dynamic> map) => TodoItem(
        id: map['id'] as String,
        title: map['title'] as String,
        description: map['description'] as String?,
        dueDate: map['due_date'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['due_date'] as int)
            : null,
        priority: map['priority'] as int? ?? 0,
        isCompleted: (map['is_completed'] as int? ?? 0) == 1,
        totalSeconds: map['total_seconds'] as int? ?? 0,
        createdAt: DateTime.fromMillisecondsSinceEpoch(
            map['created_at'] as int),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(
            map['updated_at'] as int),
      );

  TodoItem copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dueDate,
    int? priority,
    bool? isCompleted,
    int? totalSeconds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      TodoItem(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description ?? this.description,
        dueDate: dueDate ?? this.dueDate,
        priority: priority ?? this.priority,
        isCompleted: isCompleted ?? this.isCompleted,
        totalSeconds: totalSeconds ?? this.totalSeconds,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? DateTime.now(),
      );
}
