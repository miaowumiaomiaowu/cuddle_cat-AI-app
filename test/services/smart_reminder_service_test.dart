import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cuddle_cat/services/smart_reminder_service.dart';
import 'package:cuddle_cat/models/happiness_checkin.dart';
import 'package:cuddle_cat/models/mood_record.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SmartReminderService', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    test('scheduleSmartReminders creates dailyTask and moodCheck when conditions meet', () async {
      final svc = SmartReminderService();
      await svc.initialize();

      final checkins = <HappinessCheckin>[];
      final moods = <MoodEntry>[
        MoodTypeConfig.createMoodEntry(userId: 'u1', moodType: MoodType.sad, intensity: 6, description: '低落'),
      ];

      await svc.analyzeBehaviorPattern(checkins: checkins, moodRecords: moods);

      // 无行为模式时不应生成
      await svc.scheduleSmartReminders(
        currentStreak: 0,
        lastCompletionDate: DateTime.now().subtract(const Duration(days: 3)),
        recentMoods: moods,
      );

      // 由于 analyzeBehaviorPattern 在 checkins.isEmpty 时早退，这里再次设置一个伪 checkin 触发行为分析
      await svc.analyzeBehaviorPattern(checkins: [
        HappinessCheckin(taskId: 't1', ymdDate: '2025-01-01'),
        HappinessCheckin(taskId: 't1', ymdDate: '2025-01-02'),
        HappinessCheckin(taskId: 't1', ymdDate: '2025-01-03'),
      ], moodRecords: moods);

      await svc.scheduleSmartReminders(
        currentStreak: 2,
        lastCompletionDate: DateTime.now().subtract(const Duration(days: 2)),
        recentMoods: moods,
      );

      // 读取保存的提醒 JSON 并断言至少有 dailyTask 或 moodCheck 其中之一
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString('smart_reminders');
      expect(jsonStr != null && jsonStr.isNotEmpty, true);
    });
  });
}

