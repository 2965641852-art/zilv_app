import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zilv_app/database/models/todo_item.dart';
import 'package:zilv_app/features/timer/timer_provider.dart';
import 'package:zilv_app/providers/database_provider.dart';

/// 专注计时页面
class TimerPage extends ConsumerWidget {
  const TimerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerState = ref.watch(timerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('专注计时'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 关联待办选择
              _LinkedTodoSelector(
                linkedTodo: timerState.linkedTodo,
                enabled: timerState.status == TimerStatus.idle,
                onSelected: (todo) => ref
                    .read(timerProvider.notifier)
                    .setLinkedTodo(todo),
              ),
              const Spacer(),

              // 计时器显示
              Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _getCircleColor(timerState, theme),
                  boxShadow: [
                    BoxShadow(
                      color: _getCircleColor(timerState, theme)
                          .withAlpha(77),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    timerState.formattedTime,
                    style: theme.textTheme.displayLarge?.copyWith(
                      fontWeight: FontWeight.w300,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                timerState.linkedTodo?.title ?? '未关联任务',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),

              // 控制按钮
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: _buildButtons(context, ref, timerState),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Color _getCircleColor(TimerState state, ThemeData theme) {
    switch (state.status) {
      case TimerStatus.running:
        return theme.colorScheme.primary;
      case TimerStatus.paused:
        return theme.colorScheme.tertiary;
      case TimerStatus.idle:
        return theme.colorScheme.surfaceContainerHighest;
    }
  }

  List<Widget> _buildButtons(
      BuildContext context, WidgetRef ref, TimerState state) {
    switch (state.status) {
      case TimerStatus.idle:
        return [
          FilledButton.icon(
            onPressed: () => ref.read(timerProvider.notifier).start(),
            icon: const Icon(Icons.play_arrow, size: 32),
            label: const Text('开始专注',
                style: TextStyle(fontSize: 18)),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                  horizontal: 40, vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
            ),
          ),
        ];
      case TimerStatus.running:
        return [
          OutlinedButton.icon(
            onPressed: () => ref.read(timerProvider.notifier).pause(),
            icon: const Icon(Icons.pause, size: 28),
            label: const Text('暂停', style: TextStyle(fontSize: 16)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
            ),
          ),
          const SizedBox(width: 16),
          FilledButton.icon(
            onPressed: () => ref.read(timerProvider.notifier).stop(),
            icon: const Icon(Icons.stop, size: 28),
            label: const Text('结束', style: TextStyle(fontSize: 16)),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
            ),
          ),
        ];
      case TimerStatus.paused:
        return [
          FilledButton.icon(
            onPressed: () => ref.read(timerProvider.notifier).start(),
            icon: const Icon(Icons.play_arrow, size: 28),
            label: const Text('继续', style: TextStyle(fontSize: 16)),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
            ),
          ),
          const SizedBox(width: 16),
          OutlinedButton.icon(
            onPressed: () => ref.read(timerProvider.notifier).reset(),
            icon: const Icon(Icons.refresh, size: 28),
            label: const Text('重置', style: TextStyle(fontSize: 16)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
            ),
          ),
        ];
    }
  }
}

/// 关联待办选择器
class _LinkedTodoSelector extends ConsumerWidget {
  final TodoItem? linkedTodo;
  final bool enabled;
  final Function(TodoItem?) onSelected;

  const _LinkedTodoSelector({
    required this.linkedTodo,
    required this.enabled,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todoDao = ref.watch(todoDaoProvider);

    return FutureBuilder<List<TodoItem>>(
      future: todoDao.getPending(),
      builder: (context, snapshot) {
        final todos = snapshot.data ?? [];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.link),
            title: Text(linkedTodo?.title ?? '选择关联任务'),
            subtitle: linkedTodo == null ? null : Text('点击切换'),
            trailing: const Icon(Icons.chevron_right),
            enabled: enabled,
            onTap: enabled
                ? () => _showTodoPicker(context, todos)
                : null,
          ),
        );
      },
    );
  }

  void _showTodoPicker(BuildContext context, List<TodoItem> todos) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text('不关联任务'),
            leading: const Icon(Icons.block),
            onTap: () {
              onSelected(null);
              Navigator.pop(ctx);
            },
          ),
          ...todos.map((todo) => ListTile(
                title: Text(todo.title),
                subtitle: todo.dueDate != null
                    ? Text('截止 ${todo.dueDate!.month}/${todo.dueDate!.day}')
                    : null,
                leading: const Icon(Icons.task_alt),
                onTap: () {
                  onSelected(todo);
                  Navigator.pop(ctx);
                },
              )),
        ],
      ),
    );
  }
}
