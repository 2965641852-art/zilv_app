import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 待办事项列表项组件
class TodoTile extends ConsumerWidget {
  final String title;
  final bool isCompleted;
  final int priority;
  final int totalSeconds;
  final String? subtitle;
  final Color? tileColor;
  final VoidCallback? onToggle;
  final VoidCallback? onTap;

  const TodoTile({
    super.key,
    required this.title,
    this.isCompleted = false,
    this.priority = 0,
    this.totalSeconds = 0,
    this.subtitle,
    this.tileColor,
    this.onToggle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: tileColor,
      child: ListTile(
        leading: Checkbox(
          value: isCompleted,
          onChanged: (_) => onToggle?.call(),
        ),
        title: Text(
          title,
          style: TextStyle(
            decoration: isCompleted ? TextDecoration.lineThrough : null,
            color: isCompleted ? theme.colorScheme.outline : null,
          ),
        ),
        subtitle: subtitle != null ? Text(subtitle!) : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (priority > 0)
              Icon(Icons.flag, color: theme.colorScheme.error, size: 20),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, color: theme.colorScheme.outline),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
