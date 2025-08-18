import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;

class ReminderPlan {
  final String id;
  final String goalText;
  final String message;
  final int hour; // 24h
  final int minute;
  final String frequency; // 'daily' | 'weekly'
  final bool active;

  ReminderPlan({
    required this.id,
    required this.goalText,
    required this.message,
    required this.hour,
    required this.minute,
    required this.frequency,
    this.active = true,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'goalText': goalText,
        'message': message,
        'hour': hour,
        'minute': minute,
        'frequency': frequency,
        'active': active,
      };

  factory ReminderPlan.fromJson(Map<String, dynamic> json) => ReminderPlan(
        id: json['id'] as String,
        goalText: json['goalText'] as String,
        message: json['message'] as String,
        hour: json['hour'] as int,
        minute: json['minute'] as int,
        frequency: json['frequency'] as String,
        active: json['active'] as bool? ?? true,
      );
}

class ReminderService {
  static const _prefsKey = 'goal_reminder_plans';
  static const _defaultHourKey = 'goal_reminder_default_hour';
  static const _defaultMinuteKey = 'goal_reminder_default_minute';
  static const _defaultFreqKey = 'goal_reminder_default_frequency';
  final FlutterLocalNotificationsPlugin _notifier = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    tzdata.initializeTimeZones();
    const AndroidInitializationSettings androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosInit = DarwinInitializationSettings();
    const InitializationSettings initSettings = InitializationSettings(android: androidInit, iOS: iosInit);
    await _notifier.initialize(initSettings);
    // 权限请求简化处理：不同平台在首次显示时请求
    _initialized = true;
  }

  Future<List<ReminderPlan>> loadPlans() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) return [];
    try {
      final list = (jsonDecode(raw) as List)
          .cast<Map<String, dynamic>>()
          .map((e) => ReminderPlan.fromJson(e))
          .toList();
      return list;
    } catch (e) {
      debugPrint('loadPlans error: $e');
      return [];
    }
  }

  Future<void> savePlans(List<ReminderPlan> plans) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(plans.map((e) => e.toJson()).toList());
    await prefs.setString(_prefsKey, raw);
  }

  // 默认设置：时间与频率（默认 9:00, daily）
  Future<({int hour, int minute, String frequency})> getDefaultSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final h = prefs.getInt(_defaultHourKey) ?? 9;
    final m = prefs.getInt(_defaultMinuteKey) ?? 0;
    final f = prefs.getString(_defaultFreqKey) ?? 'daily';
    return (hour: h, minute: m, frequency: f);
  }

  Future<void> setDefaultSettings({required int hour, required int minute, required String frequency}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_defaultHourKey, hour);
    await prefs.setInt(_defaultMinuteKey, minute);
    await prefs.setString(_defaultFreqKey, frequency);
  }

  Future<void> schedulePlan(ReminderPlan plan) async {
    await initialize();
    final details = NotificationDetails(
      android: const AndroidNotificationDetails(
        'goal_reminders',
        '目标提醒',
        channelDescription: '基于个人目标的温暖提醒',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
      iOS: const DarwinNotificationDetails(),
    );

    final now = DateTime.now();
    DateTime firstTime = DateTime(now.year, now.month, now.day, plan.hour, plan.minute);
    if (firstTime.isBefore(now)) {
      firstTime = firstTime.add(const Duration(days: 1));
    }
    final id = plan.id.hashCode & 0x7fffffff;

    if (plan.frequency == 'weekly') {
      // 每周同一时间（按首次时间的星期），重复
      await _notifier.zonedSchedule(
        id,
        '给自己一个小鼓励',
        plan.message,
        tz.TZDateTime.from(firstTime, tz.local),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    } else {
      // 每日提醒（固定时间）
      await _notifier.zonedSchedule(
        id,
        '给自己一个小鼓励',
        plan.message,
        tz.TZDateTime.from(firstTime, tz.local),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  Future<void> cancelPlan(String planId) async {
    final id = planId.hashCode & 0x7fffffff;
    await _notifier.cancel(id);
  }

  Future<void> updatePlan(ReminderPlan updated) async {
    // 取消旧计划并重新安排
    await cancelPlan(updated.id);
    await schedulePlan(updated);
    // 写回存储
    final plans = await loadPlans();
    final idx = plans.indexWhere((p) => p.id == updated.id);
    if (idx >= 0) {
      plans[idx] = updated;
    } else {
      plans.add(updated);
    }
    await savePlans(plans);
  }

  Future<void> sendTestNotification({String title = '提醒测试', String body = '这是一个测试通知'}) async {
    await initialize();
    final details = NotificationDetails(
      android: const AndroidNotificationDetails(
        'goal_reminders', '目标提醒', channelDescription: '基于个人目标的温暖提醒',
        importance: Importance.defaultImportance, priority: Priority.defaultPriority,
      ),
      iOS: const DarwinNotificationDetails(),
    );
    final when = DateTime.now().add(const Duration(seconds: 5));
    final id = DateTime.now().millisecondsSinceEpoch & 0x7fffffff;
    await _notifier.zonedSchedule(
      id, title, body, tz.TZDateTime.from(when, tz.local), details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }
}

