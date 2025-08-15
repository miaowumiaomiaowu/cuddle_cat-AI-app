import 'package:flutter/material.dart';
import '../../services/smart_reminder_service.dart';
import '../../theme/artistic_theme.dart';

class ReminderSettingsPanel extends StatefulWidget {
  final SmartReminderService reminderService;

  const ReminderSettingsPanel({
    super.key,
    required this.reminderService,
  });

  @override
  State<ReminderSettingsPanel> createState() => _ReminderSettingsPanelState();
}

class _ReminderSettingsPanelState extends State<ReminderSettingsPanel> {
  Map<String, bool> _settings = {};
  UserBehaviorPattern? _behaviorPattern;
  List<ReminderSchedule> _upcomingReminders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _settings = Map.from(widget.reminderService.reminderSettings);
      _behaviorPattern = widget.reminderService.behaviorPattern;
      _upcomingReminders = widget.reminderService.upcomingReminders;
      _loading = false;
    });
  }

  Future<void> _updateSettings() async {
    await widget.reminderService.updateReminderSettings(_settings);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('提醒设置已保存')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('智能提醒设置', style: ArtisticTheme.titleMedium),
        const SizedBox(height: 16),
        
        // 提醒类型开关
        _buildReminderToggles(),
        
        const SizedBox(height: 24),
        
        // 行为模式分析
        if (_behaviorPattern != null) _buildBehaviorPattern(),
        
        const SizedBox(height: 24),
        
        // 即将到来的提醒
        _buildUpcomingReminders(),
        
        const SizedBox(height: 16),
        
        // 保存按钮
        ElevatedButton.icon(
          onPressed: _updateSettings,
          icon: const Icon(Icons.save),
          label: const Text('保存设置'),
        ),
      ],
    );
  }

  Widget _buildReminderToggles() {
    final reminderTypes = {
      'dailyTask': '每日任务提醒',
      'streakRisk': '连击风险提醒',
      'moodCheck': '心情检查提醒',
      'breakthrough': '突破回顾提醒',
      'achievement': '成就庆祝提醒',
      'wellness': '健康关怀提醒',
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('提醒类型', style: ArtisticTheme.titleSmall),
            const SizedBox(height: 12),
            ...reminderTypes.entries.map((entry) => SwitchListTile(
              title: Text(entry.value),
              value: _settings[entry.key] ?? true,
              onChanged: (value) {
                setState(() {
                  _settings[entry.key] = value;
                });
              },
              dense: true,
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildBehaviorPattern() {
    final pattern = _behaviorPattern!;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('你的使用习惯', style: ArtisticTheme.titleSmall),
            const SizedBox(height: 12),
            
            // 活跃时段
            Row(
              children: [
                const Icon(Icons.access_time, size: 16),
                const SizedBox(width: 8),
                Text('活跃时段: '),
                Text(
                  pattern.activeHours.map((h) => '${h}:00').join(', '),
                  style: ArtisticTheme.bodyMedium.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // 偏好星期
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16),
                const SizedBox(width: 8),
                Text('偏好星期: '),
                Text(
                  pattern.preferredDays.map(_getWeekdayName).join(', '),
                  style: ArtisticTheme.bodyMedium.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // 连击容忍度
            Row(
              children: [
                const Icon(Icons.trending_up, size: 16),
                const SizedBox(width: 8),
                Text('连击容忍度: '),
                Text(
                  '${pattern.streakTolerance}天',
                  style: ArtisticTheme.bodyMedium.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingReminders() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('即将到来的提醒', style: ArtisticTheme.titleSmall),
                const Spacer(),
                Text(
                  '${_upcomingReminders.length}条',
                  style: ArtisticTheme.caption,
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            if (_upcomingReminders.isEmpty)
              Text(
                '暂无计划中的提醒',
                style: ArtisticTheme.bodyMedium.copyWith(
                  color: Colors.grey,
                ),
              )
            else
              ..._upcomingReminders.take(3).map((reminder) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      _getReminderIcon(reminder.type),
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            reminder.title,
                            style: ArtisticTheme.bodyMedium.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            _formatReminderTime(reminder.scheduledTime),
                            style: ArtisticTheme.caption,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
          ],
        ),
      ),
    );
  }

  String _getWeekdayName(int weekday) {
    const names = ['', '周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return names[weekday];
  }

  IconData _getReminderIcon(ReminderType type) {
    switch (type) {
      case ReminderType.dailyTask:
        return Icons.task_alt;
      case ReminderType.streakRisk:
        return Icons.warning;
      case ReminderType.moodCheck:
        return Icons.mood;
      case ReminderType.breakthrough:
        return Icons.star;
      case ReminderType.achievement:
        return Icons.emoji_events;
      case ReminderType.wellness:
        return Icons.favorite;
    }
  }

  String _formatReminderTime(DateTime time) {
    final now = DateTime.now();
    final diff = time.difference(now);
    
    if (diff.inDays > 0) {
      return '${diff.inDays}天后';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}小时后';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}分钟后';
    } else {
      return '即将到来';
    }
  }
}
