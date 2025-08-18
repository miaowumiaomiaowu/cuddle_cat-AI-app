import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/reminder_service.dart';
import '../services/notification_permission_service.dart';


class ReminderSettingsScreen extends StatefulWidget {
  static const routeName = '/reminder_settings';
  const ReminderSettingsScreen({super.key});
  @override
  State<ReminderSettingsScreen> createState() => _ReminderSettingsScreenState();
}

class _ReminderSettingsScreenState extends State<ReminderSettingsScreen> {
  final ReminderService _service = ReminderService();
  int _hour = 9;
  int _minute = 0;
  String _freq = 'daily';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final d = await _service.getDefaultSettings();
    if (!mounted) return;
    setState(() { _hour = d.hour; _minute = d.minute; _freq = d.frequency; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(title: const Text('提醒默认设置')),
      body: _loading ? const Center(child: CircularProgressIndicator()) : Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _section('默认时间', Row(children: [
              DropdownButton<int>(
                value: _hour,
                items: List.generate(24, (i) => DropdownMenuItem(value: i, child: Text('${i.toString().padLeft(2,'0')}时'))),
                onChanged: (v) => setState(() => _hour = v ?? 9),
              ),
              const SizedBox(width: 12),
              DropdownButton<int>(
                value: _minute,
                items: List.generate(60, (i) => DropdownMenuItem(value: i, child: Text('${i.toString().padLeft(2,'0')}分'))),
                onChanged: (v) => setState(() => _minute = v ?? 0),
              ),
            ])),

            const SizedBox(height: 12),
            _section('默认频率', DropdownButton<String>(
              value: _freq,
              items: const [
                DropdownMenuItem(value: 'daily', child: Text('每日')),
                DropdownMenuItem(value: 'weekly', child: Text('每周')),
              ],
              onChanged: (v) => setState(() => _freq = v ?? 'daily'),
            )),

            const Spacer(),
            Row(children: [
              OutlinedButton(
                onPressed: () => setState(() { _hour = 9; _minute = 0; _freq = 'daily'; }),
                child: const Text('恢复默认(09:00 每日)')
              ),
            ]),
            const SizedBox(height: 24),
            Center(
              child: OutlinedButton.icon(
                onPressed: () async {
                  final granted = await NotificationPermissionService.ensureNotificationPermission(context);
                  if (!granted) return;
                  await _service.sendTestNotification();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已发送测试通知（5秒后）')));
                },
                icon: const Icon(Icons.notifications_active),
                label: const Text('发送测试通知'),
              ),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: () async {
                await _service.setDefaultSettings(hour: _hour, minute: _minute, frequency: _freq);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已保存默认提醒设置')));
                Navigator.pop(context);
              },
              icon: const Icon(Icons.save),
              label: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingLarge),
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMedium),
      decoration: AppTheme.handDrawnCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

