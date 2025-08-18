import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/reminder_service.dart';

class ReminderPlansScreen extends StatefulWidget {
  static const routeName = '/reminder_plans';
  const ReminderPlansScreen({super.key});
  @override
  State<ReminderPlansScreen> createState() => _ReminderPlansScreenState();
}

class _ReminderPlansScreenState extends State<ReminderPlansScreen> {
  final ReminderService _service = ReminderService();
  List<ReminderPlan> _plans = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final plans = await _service.loadPlans();
    if (!mounted) return;
    setState(() { _plans = plans; _loading = false; });
  }

  Future<void> _delete(ReminderPlan p) async {
    await _service.cancelPlan(p.id);
    final plans = await _service.loadPlans();
    plans.removeWhere((e) => e.id == p.id);
    await _service.savePlans(plans);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('提醒计划管理')),
      body: _loading ? const Center(child: CircularProgressIndicator()) : ListView.separated(
        padding: const EdgeInsets.all(AppTheme.spacingLarge),
        itemBuilder: (ctx, i) {
          final p = _plans[i];
          return ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Colors.black12)),
            title: Text(p.message),
            subtitle: Text('${p.frequency == 'daily' ? '每日' : '每周'}  ${p.hour.toString().padLeft(2,'0')}:${p.minute.toString().padLeft(2,'0')}  |  目标: ${p.goalText}'),
            trailing: Wrap(spacing: 4, children: [
              IconButton(icon: const Icon(Icons.edit), onPressed: () async {
                final updated = await _showEditDialog(context, p);
                if (updated != null) {
                  await _service.updatePlan(updated);
                  await _load();
                }
              }),
              IconButton(icon: const Icon(Icons.delete_forever), onPressed: () => _delete(p)),
            ]),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemCount: _plans.length,
      ),
    );
  }
}
  Future<ReminderPlan?> _showEditDialog(BuildContext context, ReminderPlan p) async {
    int h = p.hour; int m = p.minute; String f = p.frequency; String msg = p.message;
    final msgCtrl = TextEditingController(text: msg);
    return showDialog<ReminderPlan>(context: context, builder: (ctx) {
      return AlertDialog(
        title: const Text('编辑提醒计划'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: msgCtrl, decoration: const InputDecoration(labelText: '提醒文案')),
          const SizedBox(height: 8),
          Row(children: [
            DropdownButton<int>(value: h, items: List.generate(24, (i)=>DropdownMenuItem(value:i, child: Text('$i时'))), onChanged: (v){ h = v ?? h; }),
            const SizedBox(width: 8),
            DropdownButton<int>(value: m, items: List.generate(60, (i)=>DropdownMenuItem(value:i, child: Text('$i分'))), onChanged: (v){ m = v ?? m; }),
          ]),
          const SizedBox(height: 8),
          DropdownButton<String>(value: f, items: const [DropdownMenuItem(value:'daily', child: Text('每日')), DropdownMenuItem(value:'weekly', child: Text('每周'))], onChanged: (v){ f = v ?? f; }),
        ]),
        actions: [
          TextButton(onPressed: ()=> Navigator.of(ctx).pop(null), child: const Text('取消')),
          FilledButton(onPressed: ()=> Navigator.of(ctx).pop(ReminderPlan(id:p.id, goalText:p.goalText, message:msgCtrl.text, hour:h, minute:m, frequency:f, active:true)), child: const Text('保存')),
        ],
      );
    });
  }


