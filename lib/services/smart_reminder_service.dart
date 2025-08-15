import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/happiness_checkin.dart';
import '../models/mood_record.dart';

enum ReminderType {
  dailyTask,      // 日常任务提醒
  streakRisk,     // 连击风险提醒
  moodCheck,      // 心情检查提醒
  breakthrough,   // 突破回顾提醒
  achievement,    // 成就庆祝提醒
  wellness        // 健康关怀提醒
}

class ReminderSchedule {
  final String id;
  final ReminderType type;
  final DateTime scheduledTime;
  final String title;
  final String message;
  final Map<String, dynamic>? data;
  final bool isActive;

  ReminderSchedule({
    required this.id,
    required this.type,
    required this.scheduledTime,
    required this.title,
    required this.message,
    this.data,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'scheduledTime': scheduledTime.toIso8601String(),
    'title': title,
    'message': message,
    'data': data,
    'isActive': isActive,
  };

  factory ReminderSchedule.fromJson(Map<String, dynamic> json) => ReminderSchedule(
    id: json['id'] as String,
    type: ReminderType.values.firstWhere((e) => e.name == json['type']),
    scheduledTime: DateTime.parse(json['scheduledTime'] as String),
    title: json['title'] as String,
    message: json['message'] as String,
    data: json['data'] as Map<String, dynamic>?,
    isActive: json['isActive'] as bool? ?? true,
  );
}

class UserBehaviorPattern {
  final List<int> activeHours;        // 活跃时段
  final List<int> preferredDays;      // 偏好星期
  final double avgSessionDuration;    // 平均使用时长
  final Map<String, int> categoryPreference; // 分类偏好
  final int streakTolerance;          // 连击容忍度
  final DateTime lastActiveTime;      // 最后活跃时间

  UserBehaviorPattern({
    required this.activeHours,
    required this.preferredDays,
    required this.avgSessionDuration,
    required this.categoryPreference,
    required this.streakTolerance,
    required this.lastActiveTime,
  });

  Map<String, dynamic> toJson() => {
    'activeHours': activeHours,
    'preferredDays': preferredDays,
    'avgSessionDuration': avgSessionDuration,
    'categoryPreference': categoryPreference,
    'streakTolerance': streakTolerance,
    'lastActiveTime': lastActiveTime.toIso8601String(),
  };

  factory UserBehaviorPattern.fromJson(Map<String, dynamic> json) => UserBehaviorPattern(
    activeHours: List<int>.from(json['activeHours'] as List),
    preferredDays: List<int>.from(json['preferredDays'] as List),
    avgSessionDuration: (json['avgSessionDuration'] as num).toDouble(),
    categoryPreference: Map<String, int>.from(json['categoryPreference'] as Map),
    streakTolerance: json['streakTolerance'] as int,
    lastActiveTime: DateTime.parse(json['lastActiveTime'] as String),
  );
}

class SmartReminderService {
  static const String _remindersKey = 'smart_reminders';
  static const String _behaviorPatternKey = 'user_behavior_pattern';
  static const String _reminderSettingsKey = 'reminder_settings';
  
  List<ReminderSchedule> _reminders = [];
  UserBehaviorPattern? _behaviorPattern;
  Map<String, bool> _reminderSettings = {
    'dailyTask': true,
    'streakRisk': true,
    'moodCheck': true,
    'breakthrough': true,
    'achievement': true,
    'wellness': true,
  };

  Future<void> initialize() async {
    await _loadReminders();
    await _loadBehaviorPattern();
    await _loadReminderSettings();
  }

  Future<void> _loadReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_remindersKey);
    
    if (jsonStr != null) {
      final List<dynamic> jsonList = jsonDecode(jsonStr);
      _reminders = jsonList.map((json) => ReminderSchedule.fromJson(json)).toList();
      
      // 清理过期提醒
      _reminders.removeWhere((r) => r.scheduledTime.isBefore(DateTime.now()));
    }
  }

  Future<void> _saveReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(_reminders.map((r) => r.toJson()).toList());
    await prefs.setString(_remindersKey, jsonStr);
  }

  Future<void> _loadBehaviorPattern() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_behaviorPatternKey);
    
    if (jsonStr != null) {
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      _behaviorPattern = UserBehaviorPattern.fromJson(json);
    }
  }

  Future<void> _saveBehaviorPattern() async {
    if (_behaviorPattern == null) return;
    
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(_behaviorPattern!.toJson());
    await prefs.setString(_behaviorPatternKey, jsonStr);
  }

  Future<void> _loadReminderSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_reminderSettingsKey);
    
    if (jsonStr != null) {
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      _reminderSettings = json.map((key, value) => MapEntry(key, value as bool));
    }
  }

  Future<void> updateReminderSettings(Map<String, bool> settings) async {
    _reminderSettings.addAll(settings);
    
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(_reminderSettings);
    await prefs.setString(_reminderSettingsKey, jsonStr);
  }

  Future<void> analyzeBehaviorPattern({
    required List<HappinessCheckin> checkins,
    required List<MoodEntry> moodRecords,
  }) async {
    if (checkins.isEmpty) return;

    // 分析活跃时段
    final hourCounts = <int, int>{};
    final dayCounts = <int, int>{};
    final categoryPreference = <String, int>{};

    for (final checkin in checkins.take(50)) { // 最近50条记录
      final date = DateTime.parse('${checkin.ymdDate}T12:00:00');
      final hour = date.hour;
      final weekday = date.weekday;

      hourCounts[hour] = (hourCounts[hour] ?? 0) + 1;
      dayCounts[weekday] = (dayCounts[weekday] ?? 0) + 1;
    }

    // 获取最活跃的时段和日期
    final activeHours = hourCounts.entries
        .where((e) => e.value >= 2)
        .map((e) => e.key)
        .toList()
      ..sort();

    final preferredDays = dayCounts.entries
        .where((e) => e.value >= 3)
        .map((e) => e.key)
        .toList()
      ..sort();

    // 计算连击容忍度（基于历史连击长度）
    int maxStreak = 0;
    int currentStreak = 0;
    String? lastDate;

    final sortedCheckins = checkins.toList()
      ..sort((a, b) => a.ymdDate.compareTo(b.ymdDate));

    for (final checkin in sortedCheckins) {
      if (lastDate == null) {
        currentStreak = 1;
      } else {
        final lastDateTime = DateTime.parse('${lastDate}T00:00:00');
        final currentDateTime = DateTime.parse('${checkin.ymdDate}T00:00:00');
        final daysDiff = currentDateTime.difference(lastDateTime).inDays;

        if (daysDiff == 1) {
          currentStreak++;
        } else {
          maxStreak = max(maxStreak, currentStreak);
          currentStreak = 1;
        }
      }
      lastDate = checkin.ymdDate;
    }
    maxStreak = max(maxStreak, currentStreak);

    _behaviorPattern = UserBehaviorPattern(
      activeHours: activeHours.isNotEmpty ? activeHours : [9, 14, 20],
      preferredDays: preferredDays.isNotEmpty ? preferredDays : [1, 2, 3, 4, 5],
      avgSessionDuration: 15.0, // 简化处理
      categoryPreference: categoryPreference,
      streakTolerance: max(3, maxStreak ~/ 2),
      lastActiveTime: DateTime.now(),
    );

    await _saveBehaviorPattern();
  }

  Future<void> scheduleSmartReminders({
    required int currentStreak,
    required DateTime lastCompletionDate,
    required List<MoodEntry> recentMoods,
  }) async {
    if (_behaviorPattern == null) return;

    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);

    // 清理今天的旧提醒
    _reminders.removeWhere((r) => 
        r.scheduledTime.isBefore(tomorrow) && 
        r.scheduledTime.isAfter(DateTime(now.year, now.month, now.day)));

    // 1. 连击风险提醒
    if (_reminderSettings['streakRisk'] == true && currentStreak > 0) {
      final daysSinceLastCompletion = now.difference(lastCompletionDate).inDays;
      
      if (daysSinceLastCompletion >= 1) {
        final riskLevel = daysSinceLastCompletion / _behaviorPattern!.streakTolerance;
        
        if (riskLevel >= 0.5) {
          final reminderTime = _getOptimalReminderTime(ReminderType.streakRisk);
          
          _reminders.add(ReminderSchedule(
            id: 'streak_risk_${now.millisecondsSinceEpoch}',
            type: ReminderType.streakRisk,
            scheduledTime: reminderTime,
            title: '连击保护提醒',
            message: currentStreak >= 7 
                ? '你已经坚持了${currentStreak}天，不要让努力白费哦！'
                : '继续保持你的${currentStreak}天连击吧！',
            data: {'currentStreak': currentStreak, 'riskLevel': riskLevel},
          ));
        }
      }
    }

    // 2. 心情检查提醒
    if (_reminderSettings['moodCheck'] == true) {
      final lastMoodDate = recentMoods.isNotEmpty 
          ? recentMoods.last.timestamp
          : DateTime.now().subtract(const Duration(days: 7));
      
      final daysSinceLastMood = now.difference(lastMoodDate).inDays;
      
      if (daysSinceLastMood >= 2) {
        final reminderTime = _getOptimalReminderTime(ReminderType.moodCheck);
        
        _reminders.add(ReminderSchedule(
          id: 'mood_check_${now.millisecondsSinceEpoch}',
          type: ReminderType.moodCheck,
          scheduledTime: reminderTime,
          title: '心情记录提醒',
          message: '好久没有记录心情了，今天感觉怎么样？',
          data: {'daysSinceLastMood': daysSinceLastMood},
        ));
      }
    }

    // 3. 日常任务提醒
    if (_reminderSettings['dailyTask'] == true) {
      final reminderTime = _getOptimalReminderTime(ReminderType.dailyTask);
      
      _reminders.add(ReminderSchedule(
        id: 'daily_task_${now.millisecondsSinceEpoch}',
        type: ReminderType.dailyTask,
        scheduledTime: reminderTime,
        title: '今日小幸福',
        message: '新的一天开始了，来开启今天的幸福礼物吧！',
      ));
    }

    // 4. 健康关怀提醒
    if (_reminderSettings['wellness'] == true && recentMoods.isNotEmpty) {
      final recentNegativeMoods = recentMoods
          .where((m) => m.mood == MoodType.sad || m.mood == MoodType.angry)
          .length;
      
      if (recentNegativeMoods >= 3) {
        final reminderTime = _getOptimalReminderTime(ReminderType.wellness);

        _reminders.add(ReminderSchedule(
          id: 'wellness_${now.millisecondsSinceEpoch}',
          type: ReminderType.wellness,
          scheduledTime: reminderTime,
          title: '温暖关怀',
          message: '最近似乎有些不开心，要记得照顾好自己哦～',
          data: {'negativeMoodCount': recentNegativeMoods},
        ));
      }
    }

    await _saveReminders();
  }

  DateTime _getOptimalReminderTime(ReminderType type) {
    if (_behaviorPattern == null) {
      return DateTime.now().add(const Duration(hours: 1));
    }

    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    
    // 根据提醒类型选择最佳时间
    List<int> candidateHours;
    
    switch (type) {
      case ReminderType.dailyTask:
        candidateHours = _behaviorPattern!.activeHours.where((h) => h >= 8 && h <= 10).toList();
        break;
      case ReminderType.streakRisk:
        candidateHours = _behaviorPattern!.activeHours.where((h) => h >= 18 && h <= 21).toList();
        break;
      case ReminderType.moodCheck:
        candidateHours = _behaviorPattern!.activeHours.where((h) => h >= 20 && h <= 22).toList();
        break;
      case ReminderType.wellness:
        candidateHours = _behaviorPattern!.activeHours.where((h) => h >= 14 && h <= 16).toList();
        break;
      default:
        candidateHours = _behaviorPattern!.activeHours;
    }

    if (candidateHours.isEmpty) {
      candidateHours = [9]; // 默认上午9点
    }

    final selectedHour = candidateHours[Random().nextInt(candidateHours.length)];
    return DateTime(tomorrow.year, tomorrow.month, tomorrow.day, selectedHour);
  }

  List<ReminderSchedule> get upcomingReminders {
    final now = DateTime.now();
    return _reminders
        .where((r) => r.isActive && r.scheduledTime.isAfter(now))
        .toList()
      ..sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
  }

  List<ReminderSchedule> getTodayReminders() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    
    return _reminders
        .where((r) => r.isActive && 
                     r.scheduledTime.isAfter(today) && 
                     r.scheduledTime.isBefore(tomorrow))
        .toList()
      ..sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
  }

  Future<void> dismissReminder(String reminderId) async {
    _reminders.removeWhere((r) => r.id == reminderId);
    await _saveReminders();
  }

  UserBehaviorPattern? get behaviorPattern => _behaviorPattern;
  Map<String, bool> get reminderSettings => Map.unmodifiable(_reminderSettings);
}
