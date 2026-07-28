import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zilv_app/features/todos/todo_provider.dart';
import 'package:zilv_app/features/todos/todo_edit_page.dart';
import 'package:zilv_app/features/todos/widgets/empty_state.dart';
import 'package:zilv_app/features/todos/widgets/todo_tile.dart';

/// 待办列表页
class TodoListPage extends ConsumerWidget {
  const TodoListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(todoListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('待办清单'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(todoListProvider.notifier).loadAll(),
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.items.isEmpty
              ? const EmptyState(
                  icon: Icons.checklist_outlined,
                  title: '还没有待办事项',
                  subtitle: '点击右下角按钮添加',
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 88),
                  itemCount: state.items.length,
                  itemBuilder: (context, index) {
                    final item = state.items[index];
                    // 计算截止日期显示
                    final isOverdue = item.dueDate != null &&
                        !item.isCompleted &&
                        item.dueDate!.isBefore(DateTime.now());

                    return TodoTile(
                      title: item.title,
                      isCompleted: item.isCompleted,
                      priority: item.priority,
                      totalSeconds: item.totalSeconds,
                      subtitle: _buildSubtitle(item, isOverdue),
                      tileColor: isOverdue
                          ? Theme.of(context).colorScheme.errorContainer
                          : null,
                      onToggle: () => ref
                          .read(todoListProvider.notifier)
                          .toggleComplete(item.id),
                      onTap: () => _openEdit(context, ref, item),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEdit(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  String? _buildSubtitle(dynamic item, bool isOverdue) {
    final parts = <String>[];
    if (item.dueDate != null) {
      final dateStr =
          '${item.dueDate!.month}/${item.dueDate!.day}';
      parts.add(isOverdue ? '已过期 $dateStr' : '截止 $dateStr');
    }
    if (item.totalSeconds > 0) {
      parts.add('专注 ${_formatDuration(item.totalSeconds)}');
    }
    return parts.isNotEmpty ? parts.join(' · ') : null;
  }

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h > 0) return '${h}h${m}min';
    return '${m}min';
  }

  void _openEdit(BuildContext context, WidgetRef ref, [dynamic item]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TodoEditPage(item: item),
      ),
    );
  }
}
