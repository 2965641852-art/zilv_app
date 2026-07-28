import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zilv_app/database/models/todo_item.dart';
import 'package:zilv_app/database/todo_dao.dart';
import 'package:zilv_app/providers/database_provider.dart';

/// 待办列表状态
class TodoListState {
  final List<TodoItem> items;
  final bool isLoading;

  const TodoListState({this.items = const [], this.isLoading = false});

  TodoListState copyWith({List<TodoItem>? items, bool? isLoading}) =>
      TodoListState(
        items: items ?? this.items,
        isLoading: isLoading ?? this.isLoading,
      );
}

/// 待办列表 Provider
final todoListProvider =
    StateNotifierProvider<TodoListNotifier, TodoListState>((ref) {
  final dao = ref.watch(todoDaoProvider);
  return TodoListNotifier(dao);
});

class TodoListNotifier extends StateNotifier<TodoListState> {
  final TodoDao _dao;

  TodoListNotifier(this._dao) : super(const TodoListState()) {
    loadAll();
  }

  /// 加载所有待办
  Future<void> loadAll() async {
    state = state.copyWith(isLoading: true);
    final items = await _dao.getAll();
    state = TodoListState(items: items);
  }

  /// 添加待办
  Future<void> add(TodoItem item) async {
    await _dao.insert(item);
    await loadAll();
  }

  /// 更新待办
  Future<void> update(TodoItem item) async {
    await _dao.update(item);
    await loadAll();
  }

  /// 切换完成状态
  Future<void> toggleComplete(String id) async {
    await _dao.toggleComplete(id);
    await loadAll();
  }

  /// 删除待办
  Future<void> delete(String id) async {
    await _dao.delete(id);
    await loadAll();
  }
}
