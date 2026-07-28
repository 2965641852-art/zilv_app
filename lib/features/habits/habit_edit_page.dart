import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zilv_app/features/habits/habit_provider.dart';

/// 新建习惯页面
class HabitEditPage extends ConsumerStatefulWidget {
  const HabitEditPage({super.key});

  @override
  ConsumerState<HabitEditPage> createState() => _HabitEditPageState();
}

class _HabitEditPageState extends ConsumerState<HabitEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _frequency = 'daily';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('新建习惯')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: '习惯名称',
                hintText: '例如：每天阅读30分钟',
                prefixIcon: Icon(Icons.favorite_border),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? '请输入习惯名称' : null,
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descCtrl,
              decoration: const InputDecoration(
                labelText: '描述（可选）',
                hintText: '写下你的目标',
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.repeat),
                    title: const Text('频率'),
                    trailing: DropdownButton<String>(
                      value: _frequency,
                      items: [
                        DropdownMenuItem(value: 'daily', child: Text('每天')),
                        DropdownMenuItem(value: 'weekly', child: Text('每周')),
                      ],
                      onChanged: (v) =>
                          setState(() => _frequency = v ?? 'daily'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check),
              label: const Text('创建习惯'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    ref.read(habitListProvider.notifier).add(
          _nameCtrl.text.trim(),
          _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
          _frequency,
        );
    Navigator.pop(context);
  }
}
