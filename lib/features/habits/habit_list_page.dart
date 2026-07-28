import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zilv_app/features/habits/habit_provider.dart';
import 'package:zilv_app/features/habits/habit_edit_page.dart';
import 'package:zilv_app/features/todos/widgets/empty_state.dart';

/// 习惯打卡页
class HabitListPage extends ConsumerWidget {
  const HabitListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(habitListProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('习惯打卡'),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.habits.isEmpty
              ? const EmptyState(
                  icon: Icons.favorite_outlined,
                  title: '还没有习惯',
                  subtitle: '添加一个习惯开始打卡吧',
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 88),
                  itemCount: state.habits.length,
                  itemBuilder: (context, index) {
                    final habit = state.habits[index];
                    final checked =
                        state.todayChecked[habit.id] ?? false;
                    final streak = state.streakDays[habit.id] ?? 0;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: checked
                              ? theme.colorScheme.primaryContainer
                              : theme.colorScheme.surfaceContainerHighest,
                          child: Icon(
                            checked ? Icons.check : Icons.favorite_border,
                            color: checked
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outline,
                          ),
                        ),
                        title: Text(
                          habit.name,
                          style: TextStyle(
                            decoration: checked
                                ? TextDecoration.lineThrough
                                : null,
                            color: checked
                                ? theme.colorScheme.outline
                                : null,
                          ),
                        ),
                        subtitle: streak > 0
                            ? Text('🔥 连续 $streak 天')
                            : habit.description != null
                                ? Text(habit.description!)
                                : null,
                        trailing: Checkbox(
                          value: checked,
                          onChanged: (_) => ref
                              .read(habitListProvider.notifier)
                              .toggleCheckIn(habit.id),
                        ),
                        onLongPress: () => _confirmDelete(
                            context, ref, habit.id, habit.name),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const HabitEditPage()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, WidgetRef ref, String id, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除习惯'),
        content: Text('确定要删除「$name」吗？\n相关打卡记录也会被删除。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              ref.read(habitListProvider.notifier).delete(id);
              Navigator.pop(ctx);
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
