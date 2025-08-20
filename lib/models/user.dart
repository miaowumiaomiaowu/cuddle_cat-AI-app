import 'package:flutter/material.dart';

/// 用户模型
class User {
  final String id;
  final String username;
  final String email;
  final String? phone;
  final String? avatar; // 头像URL或本地路径
  final DateTime? birthday;
  final String? bio; // 个人简介
  final UserSettings settings;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final UserStats stats; // 用户统计数据

  User({
    required this.id,
    required this.username,
    required this.email,
    this.phone,
    this.avatar,
    this.birthday,
    this.bio,
    required this.settings,
    required this.createdAt,
    required this.lastLoginAt,
    required this.stats,
  });

  /// 从JSON创建User
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      avatar: json['avatar'] as String?,
      birthday: json['birthday'] != null 
          ? DateTime.parse(json['birthday'] as String) 
          : null,
      bio: json['bio'] as String?,
      settings: UserSettings.fromJson(json['settings'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastLoginAt: DateTime.parse(json['lastLoginAt'] as String),
      stats: UserStats.fromJson(json['stats'] as Map<String, dynamic>),
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'phone': phone,
      'avatar': avatar,
      'birthday': birthday?.toIso8601String(),
      'bio': bio,
      'settings': settings.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt.toIso8601String(),
      'stats': stats.toJson(),
    };
  }

  /// 复制并修改
  User copyWith({
    String? id,
    String? username,
    String? email,
    String? phone,
    String? avatar,
    DateTime? birthday,
    String? bio,
    UserSettings? settings,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    UserStats? stats,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatar: avatar ?? this.avatar,
      birthday: birthday ?? this.birthday,
      bio: bio ?? this.bio,
      settings: settings ?? this.settings,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      stats: stats ?? this.stats,
    );
  }

  /// 获取年龄
  int? get age {
    if (birthday == null) return null;
    final now = DateTime.now();
    int age = now.year - birthday!.year;
    if (now.month < birthday!.month || 
        (now.month == birthday!.month && now.day < birthday!.day)) {
      age--;
    }
    return age;
  }

  /// 获取注册天数
  int get daysSinceRegistration {
    return DateTime.now().difference(createdAt).inDays;
  }

  /// 是否为新用户（注册不到7天）
  bool get isNewUser {
    return daysSinceRegistration < 7;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'User(id: $id, username: $username, email: $email)';
  }
}

/// 用户设置
class UserSettings {
  final bool notificationsEnabled; // 通知开关
  final bool soundEnabled; // 声音开关
  final bool hapticEnabled; // 触觉反馈开关
  final ThemeMode themeMode; // 主题模式
  final String language; // 语言设置
  final bool dataAnalyticsEnabled; // 数据分析开关
  final bool locationEnabled; // 位置服务开关
  final ReminderSettings reminderSettings; // 提醒设置
  final PrivacySettings privacySettings; // 隐私设置

  UserSettings({
    this.notificationsEnabled = true,
    this.soundEnabled = true,
    this.hapticEnabled = true,
    this.themeMode = ThemeMode.system,
    this.language = 'zh_CN',
    this.dataAnalyticsEnabled = true,
    this.locationEnabled = true,
    required this.reminderSettings,
    required this.privacySettings,
  });

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      soundEnabled: json['soundEnabled'] as bool? ?? true,
      hapticEnabled: json['hapticEnabled'] as bool? ?? true,
      themeMode: ThemeMode.values.firstWhere(
        (e) => e.toString() == json['themeMode'],
        orElse: () => ThemeMode.system,
      ),
      language: json['language'] as String? ?? 'zh_CN',
      dataAnalyticsEnabled: json['dataAnalyticsEnabled'] as bool? ?? true,
      locationEnabled: json['locationEnabled'] as bool? ?? true,
      reminderSettings: ReminderSettings.fromJson(
        json['reminderSettings'] as Map<String, dynamic>? ?? {},
      ),
      privacySettings: PrivacySettings.fromJson(
        json['privacySettings'] as Map<String, dynamic>? ?? {},
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notificationsEnabled': notificationsEnabled,
      'soundEnabled': soundEnabled,
      'hapticEnabled': hapticEnabled,
      'themeMode': themeMode.toString(),
      'language': language,
      'dataAnalyticsEnabled': dataAnalyticsEnabled,
      'locationEnabled': locationEnabled,
      'reminderSettings': reminderSettings.toJson(),
      'privacySettings': privacySettings.toJson(),
    };
  }

  UserSettings copyWith({
    bool? notificationsEnabled,
    bool? soundEnabled,
    bool? hapticEnabled,
    ThemeMode? themeMode,
    String? language,
    bool? dataAnalyticsEnabled,
    bool? locationEnabled,
    ReminderSettings? reminderSettings,
    PrivacySettings? privacySettings,
  }) {
    return UserSettings(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      hapticEnabled: hapticEnabled ?? this.hapticEnabled,
      themeMode: themeMode ?? this.themeMode,
      language: language ?? this.language,
      dataAnalyticsEnabled: dataAnalyticsEnabled ?? this.dataAnalyticsEnabled,
      locationEnabled: locationEnabled ?? this.locationEnabled,
      reminderSettings: reminderSettings ?? this.reminderSettings,
      privacySettings: privacySettings ?? this.privacySettings,
    );
  }
}

/// 提醒设置
class ReminderSettings {
  final bool dailyMoodReminder; // 每日心情提醒
  final TimeOfDay? reminderTime; // 提醒时间
  final List<int> reminderDays; // 提醒日期（1-7，周一到周日）
  final bool gratitudeReminder; // 感恩提醒
  final bool weeklyReportReminder; // 周报提醒

  ReminderSettings({
    this.dailyMoodReminder = true,
    this.reminderTime,
    this.reminderDays = const [1, 2, 3, 4, 5, 6, 7], // 默认每天
    this.gratitudeReminder = true,
    this.weeklyReportReminder = true,
  });

  factory ReminderSettings.fromJson(Map<String, dynamic> json) {
    TimeOfDay? reminderTime;
    if (json['reminderTime'] != null) {
      final timeData = json['reminderTime'] as Map<String, dynamic>;
      reminderTime = TimeOfDay(
        hour: timeData['hour'] as int,
        minute: timeData['minute'] as int,
      );
    }

    return ReminderSettings(
      dailyMoodReminder: json['dailyMoodReminder'] as bool? ?? true,
      reminderTime: reminderTime,
      reminderDays: List<int>.from(json['reminderDays'] as List? ?? [1, 2, 3, 4, 5, 6, 7]),
      gratitudeReminder: json['gratitudeReminder'] as bool? ?? true,
      weeklyReportReminder: json['weeklyReportReminder'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dailyMoodReminder': dailyMoodReminder,
      'reminderTime': reminderTime != null ? {
        'hour': reminderTime!.hour,
        'minute': reminderTime!.minute,
      } : null,
      'reminderDays': reminderDays,
      'gratitudeReminder': gratitudeReminder,
      'weeklyReportReminder': weeklyReportReminder,
    };
  }

  ReminderSettings copyWith({
    bool? dailyMoodReminder,
    TimeOfDay? reminderTime,
    List<int>? reminderDays,
    bool? gratitudeReminder,
    bool? weeklyReportReminder,
  }) {
    return ReminderSettings(
      dailyMoodReminder: dailyMoodReminder ?? this.dailyMoodReminder,
      reminderTime: reminderTime ?? this.reminderTime,
      reminderDays: reminderDays ?? this.reminderDays,
      gratitudeReminder: gratitudeReminder ?? this.gratitudeReminder,
      weeklyReportReminder: weeklyReportReminder ?? this.weeklyReportReminder,
    );
  }
}

/// 隐私设置
class PrivacySettings {
  final bool allowDataCollection; // 允许数据收集
  final bool allowAnalytics; // 允许分析
  final bool allowLocationTracking; // 允许位置追踪
  final bool allowCrashReporting; // 允许崩溃报告
  final bool allowPersonalization; // 允许个性化

  PrivacySettings({
    this.allowDataCollection = true,
    this.allowAnalytics = true,
    this.allowLocationTracking = true,
    this.allowCrashReporting = true,
    this.allowPersonalization = true,
  });

  factory PrivacySettings.fromJson(Map<String, dynamic> json) {
    return PrivacySettings(
      allowDataCollection: json['allowDataCollection'] as bool? ?? true,
      allowAnalytics: json['allowAnalytics'] as bool? ?? true,
      allowLocationTracking: json['allowLocationTracking'] as bool? ?? true,
      allowCrashReporting: json['allowCrashReporting'] as bool? ?? true,
      allowPersonalization: json['allowPersonalization'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'allowDataCollection': allowDataCollection,
      'allowAnalytics': allowAnalytics,
      'allowLocationTracking': allowLocationTracking,
      'allowCrashReporting': allowCrashReporting,
      'allowPersonalization': allowPersonalization,
    };
  }

  PrivacySettings copyWith({
    bool? allowDataCollection,
    bool? allowAnalytics,
    bool? allowLocationTracking,
    bool? allowCrashReporting,
    bool? allowPersonalization,
  }) {
    return PrivacySettings(
      allowDataCollection: allowDataCollection ?? this.allowDataCollection,
      allowAnalytics: allowAnalytics ?? this.allowAnalytics,
      allowLocationTracking: allowLocationTracking ?? this.allowLocationTracking,
      allowCrashReporting: allowCrashReporting ?? this.allowCrashReporting,
      allowPersonalization: allowPersonalization ?? this.allowPersonalization,
    );
  }
}

/// 用户统计数据
class UserStats {
  final int totalMoodEntries; // 总心情记录数
  final int consecutiveDays; // 连续记录天数
  final int longestStreak; // 最长连续记录
  final DateTime? lastMoodEntry; // 最后一次心情记录


  UserStats({
    this.totalMoodEntries = 0,
    this.consecutiveDays = 0,
    this.longestStreak = 0,
    this.lastMoodEntry,

  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      totalMoodEntries: json['totalMoodEntries'] as int? ?? 0,
      consecutiveDays: json['consecutiveDays'] as int? ?? 0,
      longestStreak: json['longestStreak'] as int? ?? 0,
      lastMoodEntry: json['lastMoodEntry'] != null
          ? DateTime.parse(json['lastMoodEntry'] as String)
          : null,

    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalMoodEntries': totalMoodEntries,
      'consecutiveDays': consecutiveDays,
      'longestStreak': longestStreak,
      'lastMoodEntry': lastMoodEntry?.toIso8601String(),

    };
  }

  UserStats copyWith({
    int? totalMoodEntries,
    int? consecutiveDays,
    int? longestStreak,
    DateTime? lastMoodEntry,

  }) {
    return UserStats(
      totalMoodEntries: totalMoodEntries ?? this.totalMoodEntries,
      consecutiveDays: consecutiveDays ?? this.consecutiveDays,
      longestStreak: longestStreak ?? this.longestStreak,
      lastMoodEntry: lastMoodEntry ?? this.lastMoodEntry,

    );
  }
}
