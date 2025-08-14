import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/happiness_task.dart';
import '../providers/happiness_provider.dart';

class HappinessTaskEditScreen extends StatefulWidget {
  static const routeName = '/happiness/edit';
  final HappinessTask? task;
  const HappinessTaskEditScreen({super.key, this.task});

  @override
  State<HappinessTaskEditScreen> createState() => _HappinessTaskEditScreenState();
}

class _HappinessTaskEditScreenState extends State<HappinessTaskEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _title;
  late TextEditingController _desc;
  String _emoji = '🌿';
  String _category = 'selfcare';
  String _frequency = 'daily';
  int? _minutes = 5;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.task?.title ?? '');
    _desc = TextEditingController(text: widget.task?.description ?? '');
    _emoji = widget.task?.emoji ?? '🌿';
    _category = widget.task?.category ?? 'selfcare';
    _frequency = widget.task?.frequency ?? 'daily';
    _minutes = widget.task?.estimatedMinutes ?? 5;
  }

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('编辑幸福任务')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _title,
                decoration: const InputDecoration(labelText: '标题'),
                validator: (v) => v == null || v.trim().isEmpty ? '请输入标题' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _desc,
                decoration: const InputDecoration(labelText: '描述（可选）'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _category,
                items: const [
                  DropdownMenuItem(value: 'selfcare', child: Text('自我关怀')),
                  DropdownMenuItem(value: 'mind', child: Text('身心放松')),
                  DropdownMenuItem(value: 'body', child: Text('身体活动')),
                  DropdownMenuItem(value: 'social', child: Text('社交联系')),
                  DropdownMenuItem(value: 'creative', child: Text('创意表达')),
                ],
                onChanged: (v) => setState(() => _category = v ?? 'selfcare'),
                decoration: const InputDecoration(labelText: '类别'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _frequency,
                items: const [
                  DropdownMenuItem(value: 'once', child: Text('一次性')),
                  DropdownMenuItem(value: 'daily', child: Text('每天')),
                  DropdownMenuItem(value: 'weekly', child: Text('每周')),
                  DropdownMenuItem(value: 'workdays', child: Text('工作日')),
                ],
                onChanged: (v) => setState(() => _frequency = v ?? 'daily'),
                decoration: const InputDecoration(labelText: '频率'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: _minutes?.toString() ?? '5',
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: '预计分钟'),
                onChanged: (v) => _minutes = int.tryParse(v),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _save,
                child: const Text('保存'),
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final hp = Provider.of<HappinessProvider>(context, listen: false);
    final task = HappinessTask(
      id: widget.task?.id,
      title: _title.text.trim(),
      emoji: _emoji,
      category: _category,
      description: _desc.text.trim(),
      estimatedMinutes: _minutes,
      frequency: _frequency,
    );
    await hp.addOrUpdateTask(task);
    if (mounted) Navigator.of(context).pop(true);
  }
}

