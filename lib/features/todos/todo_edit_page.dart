import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zilv_app/database/models/todo_item.dart';
import 'package:zilv_app/features/todos/todo_provider.dart';
import 'package:uuid/uuid.dart';

/// 新建/编辑待办页面
class TodoEditPage extends ConsumerStatefulWidget {
  final TodoItem? item; // null = 新建, 非null = 编辑

  const TodoEditPage({super.key, this.item});

  @override
  ConsumerState<TodoEditPage> createState() => _TodoEditPageState();
}

class _TodoEditPageState extends ConsumerState<TodoEditPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late DateTime? _dueDate;
  late int _priority;

  bool get isEditing => widget.item != null;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _titleCtrl = TextEditingController(text: item?.title ?? '');
    _descCtrl = TextEditingController(text: item?.description ?? '');
    _dueDate = item?.dueDate;
    _priority = item?.priority ?? 0;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? '编辑待办' : '新建待办'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 标题
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: '标题',
                hintText: '请输入待办事项',
                prefixIcon: Icon(Icons.task_alt),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? '请输入标题' : null,
              autofocus: true,
            ),
            const SizedBox(height: 16),

            // 描述
            TextFormField(
              controller: _descCtrl,
              decoration: const InputDecoration(
                labelText: '描述（可选）',
                hintText: '添加更多细节',
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // 截止日期
            Card(
              child: ListTile(
                leading: const Icon(Icons.calendar_today),
                title: Text(_dueDate != null
                    ? '${_dueDate!.year}-${_dueDate!.month.toString().padLeft(2, '0')}-${_dueDate!.day.toString().padLeft(2, '0')}'
                    : '设置截止日期'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_dueDate != null)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _dueDate = null),
                      ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
                onTap: _pickDate,
              ),
            ),
            const SizedBox(height: 16),

            // 优先级
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.flag),
                    title: const Text('优先级'),
                    subtitle: Text(_priority == 0 ? '普通' : '重要'),
                    trailing: Switch(
                      value: _priority == 1,
                      onChanged: (v) => setState(() => _priority = v ? 1 : 0),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // 保存按钮
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check),
              label: Text(isEditing ? '保存修改' : '添加待办'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initialDate = _dueDate ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final now = DateTime.now();
    final item = TodoItem(
      id: widget.item?.id ?? const Uuid().v4(),
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      dueDate: _dueDate,
      priority: _priority,
      isCompleted: widget.item?.isCompleted ?? false,
      totalSeconds: widget.item?.totalSeconds ?? 0,
      createdAt: widget.item?.createdAt ?? now,
      updatedAt: now,
    );

    if (isEditing) {
      ref.read(todoListProvider.notifier).update(item);
    } else {
      ref.read(todoListProvider.notifier).add(item);
    }

    Navigator.pop(context);
  }
}
