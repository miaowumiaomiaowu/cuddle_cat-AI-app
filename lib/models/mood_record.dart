import 'package:flutter/material.dart';

/// 心情记录模型 - 专注于心理治愈和情感记录
class MoodEntry {
  final String id;
  final String userId; // 用户ID
  final MoodType mood; // 主要心情类型
  final String emoji; // 对应的emoji
  final int intensity; // 心情强度 1-10
  final String? description; // 详细描述
  final List<String> tags; // 标签（工作、家庭、健康等）
  final String? trigger; // 触发事件
  final List<String> photos; // 照片路径
  final String? location; // 地点（可选）
  final String? weather; // 天气（可选）
  final DateTime timestamp;
  final Color color; // 心情对应的颜色

  // 感恩记录 - 治愈功能
  final List<String> gratitude; // 感恩的事情

  // 隐私设置
  final bool isPrivate; // 是否私密
  final bool allowAnalytics; // 是否允许分析

  MoodEntry({
    required this.id,
    required this.userId,
    required this.mood,
    required this.emoji,
    required this.intensity,
    this.description,
    this.tags = const [],
    this.trigger,
    this.photos = const [],
    this.location,
    this.weather,
    required this.timestamp,
    required this.color,
    this.gratitude = const [],
    this.isPrivate = false,
    this.allowAnalytics = true,
  });

  /// 从JSON创建MoodEntry
  factory MoodEntry.fromJson(Map<String, dynamic> json) {
    return MoodEntry(
      id: json['id'] as String,
      userId: json['userId'] as String,
      mood: MoodType.values.firstWhere(
        (e) => e.toString() == json['mood'],
        orElse: () => MoodType.neutral,
      ),
      emoji: json['emoji'] as String,
      intensity: json['intensity'] as int,
      description: json['description'] as String?,
      tags: List<String>.from(json['tags'] as List? ?? []),
      trigger: json['trigger'] as String?,
      photos: List<String>.from(json['photos'] as List? ?? []),
      location: json['location'] as String?,
      weather: json['weather'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      color: Color(json['color'] as int),
      gratitude: List<String>.from(json['gratitude'] as List? ?? []),
      isPrivate: json['isPrivate'] as bool? ?? false,
      allowAnalytics: json['allowAnalytics'] as bool? ?? true,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'mood': mood.toString(),
      'emoji': emoji,
      'intensity': intensity,
      'description': description,
      'tags': tags,
      'trigger': trigger,
      'photos': photos,
      'location': location,
      'weather': weather,
      'timestamp': timestamp.toIso8601String(),
      'color': color.value,
      'gratitude': gratitude,
      'isPrivate': isPrivate,
      'allowAnalytics': allowAnalytics,
    };
  }

  /// 复制并修改
  MoodEntry copyWith({
    String? id,
    String? userId,
    MoodType? mood,
    String? emoji,
    int? intensity,
    String? description,
    List<String>? tags,
    String? trigger,
    List<String>? photos,
    String? location,
    String? weather,
    DateTime? timestamp,
    Color? color,
    List<String>? gratitude,
    bool? isPrivate,
    bool? allowAnalytics,
  }) {
    return MoodEntry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      mood: mood ?? this.mood,
      emoji: emoji ?? this.emoji,
      intensity: intensity ?? this.intensity,
      description: description ?? this.description,
      tags: tags ?? this.tags,
      trigger: trigger ?? this.trigger,
      photos: photos ?? this.photos,
      location: location ?? this.location,
      weather: weather ?? this.weather,
      timestamp: timestamp ?? this.timestamp,
      color: color ?? this.color,
      gratitude: gratitude ?? this.gratitude,
      isPrivate: isPrivate ?? this.isPrivate,
      allowAnalytics: allowAnalytics ?? this.allowAnalytics,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MoodEntry && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'MoodEntry(id: $id, mood: $mood, emoji: $emoji, timestamp: $timestamp)';
  }

  /// 获取心情强度描述
  String get intensityDescription {
    if (intensity <= 2) return '很轻微';
    if (intensity <= 4) return '轻微';
    if (intensity <= 6) return '中等';
    if (intensity <= 8) return '强烈';
    return '非常强烈';
  }

  /// 是否为积极心情
  bool get isPositive {
    return [
      MoodType.happy,
      MoodType.excited,
      MoodType.grateful,
      MoodType.peaceful,
      MoodType.confident,
      MoodType.loving,
    ].contains(mood);
  }

  /// 是否为消极心情
  bool get isNegative {
    return [
      MoodType.sad,
      MoodType.angry,
      MoodType.anxious,
      MoodType.frustrated,
      MoodType.lonely,
      MoodType.stressed,
    ].contains(mood);
  }
}

/// 心情类型枚举 - 专注于心理健康
enum MoodType {
  // 积极情绪
  happy,      // 开心
  excited,    // 兴奋
  grateful,   // 感恩
  peaceful,   // 平静
  confident,  // 自信
  loving,     // 充满爱意

  // 中性情绪
  neutral,    // 中性
  tired,      // 疲惫
  bored,      // 无聊

  // 消极情绪
  sad,        // 难过
  angry,      // 愤怒
  anxious,    // 焦虑
  frustrated, // 沮丧
  lonely,     // 孤独
  stressed,   // 压力大
}

/// 心情类型配置 - 专注于心理健康和治愈
class MoodTypeConfig {
  static const Map<MoodType, Map<String, dynamic>> moodConfigs = {
    // 积极情绪
    MoodType.happy: {
      'name': '开心',
      'emoji': '😊',
      'color': 0xFFFFD700, // 金色
      'description': '感到快乐和满足',
    },
    MoodType.excited: {
      'name': '兴奋',
      'emoji': '🤩',
      'color': 0xFFFF6B6B, // 红色
      'description': '充满活力和期待',
    },
    MoodType.grateful: {
      'name': '感恩',
      'emoji': '🙏',
      'color': 0xFFE8C4A0, // 温暖金
      'description': '对生活充满感激',
    },
    MoodType.peaceful: {
      'name': '平静',
      'emoji': '😌',
      'color': 0xFF9BB0C1, // 柔和蓝
      'description': '内心宁静祥和',
    },
    MoodType.confident: {
      'name': '自信',
      'emoji': '😎',
      'color': 0xFF9ABEAA, // 薄荷绿
      'description': '对自己充满信心',
    },
    MoodType.loving: {
      'name': '充满爱意',
      'emoji': '🥰',
      'color': 0xFFCB9CA1, // 玫瑰灰
      'description': '感受到爱与被爱',
    },

    // 中性情绪
    MoodType.neutral: {
      'name': '平常',
      'emoji': '😐',
      'color': 0xFFB5A490, // 暖灰
      'description': '情绪平稳，没有特别感受',
    },
    MoodType.tired: {
      'name': '疲惫',
      'emoji': '😴',
      'color': 0xFF9B8B7D, // 浅棕色
      'description': '身心感到疲劳',
    },
    MoodType.bored: {
      'name': '无聊',
      'emoji': '😑',
      'color': 0xFFA9A9A9, // 深灰色
      'description': '缺乏兴趣和动力',
    },

    // 消极情绪
    MoodType.sad: {
      'name': '难过',
      'emoji': '😢',
      'color': 0xFF87CEEB, // 天蓝色
      'description': '感到悲伤和失落',
    },
    MoodType.angry: {
      'name': '愤怒',
      'emoji': '😠',
      'color': 0xFFFF8C42, // 橙色
      'description': '感到生气和不满',
    },
    MoodType.anxious: {
      'name': '焦虑',
      'emoji': '😰',
      'color': 0xFFD4B896, // 柔和橙
      'description': '感到担心和不安',
    },
    MoodType.frustrated: {
      'name': '沮丧',
      'emoji': '😤',
      'color': 0xFFB19CD9, // 紫色
      'description': '感到挫败和失望',
    },
    MoodType.lonely: {
      'name': '孤独',
      'emoji': '😔',
      'color': 0xFF708090, // 石板灰
      'description': '感到孤单和寂寞',
    },
    MoodType.stressed: {
      'name': '压力大',
      'emoji': '😵',
      'color': 0xFFFF69B4, // 粉色
      'description': '感到压力和紧张',
    },
  };

  /// 获取所有心情类型
  static List<MoodType> getAllMoodTypes() {
    return MoodType.values;
  }

  /// 根据心情类型获取配置信息
  static Map<String, dynamic>? getMoodConfig(MoodType moodType) {
    return moodConfigs[moodType];
  }

  /// 获取心情名称
  static String getMoodName(MoodType moodType) {
    return moodConfigs[moodType]?['name'] as String? ?? '未知';
  }

  /// 获取心情emoji
  static String getMoodEmoji(MoodType moodType) {
    return moodConfigs[moodType]?['emoji'] as String? ?? '😐';
  }

  /// 获取心情颜色
  static Color getMoodColor(MoodType moodType) {
    final colorValue = moodConfigs[moodType]?['color'] as int?;
    return Color(colorValue ?? 0xFFB5A490);
  }

  /// 获取心情描述
  static String getMoodDescription(MoodType moodType) {
    return moodConfigs[moodType]?['description'] as String? ?? '';
  }

  /// 创建心情记录
  static MoodEntry createMoodEntry({
    required String userId,
    required MoodType moodType,
    int intensity = 5,
    String? description,
    List<String> tags = const [],
    String? trigger,
    List<String> photos = const [],
    String? location,
    List<String> gratitude = const [],
    bool isPrivate = false,
  }) {
    return MoodEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      mood: moodType,
      emoji: getMoodEmoji(moodType),
      intensity: intensity,
      description: description,
      tags: tags,
      trigger: trigger,
      photos: photos,
      location: location,
      timestamp: DateTime.now(),
      color: getMoodColor(moodType),
      gratitude: gratitude,
      isPrivate: isPrivate,
    );
  }

  /// 获取积极心情类型
  static List<MoodType> getPositiveMoods() {
    return [
      MoodType.happy,
      MoodType.excited,
      MoodType.grateful,
      MoodType.peaceful,
      MoodType.confident,
      MoodType.loving,
    ];
  }

  /// 获取消极心情类型
  static List<MoodType> getNegativeMoods() {
    return [
      MoodType.sad,
      MoodType.angry,
      MoodType.anxious,
      MoodType.frustrated,
      MoodType.lonely,
      MoodType.stressed,
    ];
  }

  /// 获取中性心情类型
  static List<MoodType> getNeutralMoods() {
    return [
      MoodType.neutral,
      MoodType.tired,
      MoodType.bored,
    ];
  }
}

/// 心情分析数据 - 专注于心理健康洞察
class MoodAnalytics {
  final String userId;
  final DateTimeRange period;

  // 基础统计
  final Map<MoodType, int> moodDistribution; // 心情分布
  final double averageIntensity; // 平均强度
  final int totalEntries; // 总记录数

  // 趋势分析
  final List<MoodTrendPoint> dailyTrend; // 每日趋势
  final List<MoodTrendPoint> weeklyTrend; // 周趋势
  final List<MoodTrendPoint> monthlyTrend; // 月趋势

  // 模式识别
  final List<MoodPattern> patterns; // 心情模式
  final List<String> insights; // 洞察
  final List<String> recommendations; // 建议

  // 改善指标
  final double improvementScore; // 改善分数 0-100
  final List<Achievement> achievements; // 成就
  final MoodType dominantMood; // 主导心情
  final double positiveRatio; // 积极心情占比
  final double negativeRatio; // 消极心情占比

  MoodAnalytics({
    required this.userId,
    required this.period,
    required this.moodDistribution,
    required this.averageIntensity,
    required this.totalEntries,
    required this.dailyTrend,
    required this.weeklyTrend,
    required this.monthlyTrend,
    required this.patterns,
    required this.insights,
    required this.recommendations,
    required this.improvementScore,
    required this.achievements,
    required this.dominantMood,
    required this.positiveRatio,
    required this.negativeRatio,
  });

  /// 从心情记录列表计算分析数据
  factory MoodAnalytics.fromEntries(List<MoodEntry> entries, {
    DateTimeRange? period,
  }) {
    final now = DateTime.now();
    final analysisRange = period ?? DateTimeRange(
      start: now.subtract(const Duration(days: 30)),
      end: now,
    );

    if (entries.isEmpty) {
      return MoodAnalytics(
        userId: '',
        period: analysisRange,
        moodDistribution: {},
        averageIntensity: 5.0,
        totalEntries: 0,
        dailyTrend: [],
        weeklyTrend: [],
        monthlyTrend: [],
        patterns: [],
        insights: [],
        recommendations: [],
        improvementScore: 50.0,
        achievements: [],
        dominantMood: MoodType.neutral,
        positiveRatio: 0.0,
        negativeRatio: 0.0,
      );
    }

    // 计算基础统计
    final Map<MoodType, int> moodDistribution = {};
    double totalIntensity = 0;
    int positiveCount = 0;
    int negativeCount = 0;

    for (final entry in entries) {
      moodDistribution[entry.mood] = (moodDistribution[entry.mood] ?? 0) + 1;
      totalIntensity += entry.intensity;

      if (entry.isPositive) positiveCount++;
      if (entry.isNegative) negativeCount++;
    }

    // 找出主导心情
    MoodType dominantMood = MoodType.neutral;
    int maxCount = 0;
    moodDistribution.forEach((mood, count) {
      if (count > maxCount) {
        maxCount = count;
        dominantMood = mood;
      }
    });

    // 计算比例
    final total = entries.length;
    final positiveRatio = total > 0 ? positiveCount / total : 0.0;
    final negativeRatio = total > 0 ? negativeCount / total : 0.0;

    // 计算改善分数（基于积极心情占比和平均强度）
    final avgIntensity = totalIntensity / entries.length;
    final improvementScore = (positiveRatio * 50) + ((avgIntensity / 10) * 50);

    return MoodAnalytics(
      userId: entries.isNotEmpty ? entries.first.userId : '',
      period: analysisRange,
      moodDistribution: moodDistribution,
      averageIntensity: avgIntensity,
      totalEntries: entries.length,
      dailyTrend: _calculateDailyTrend(entries),
      weeklyTrend: _calculateWeeklyTrend(entries),
      monthlyTrend: _calculateMonthlyTrend(entries),
      patterns: _identifyPatterns(entries),
      insights: _generateInsights(entries, positiveRatio, negativeRatio),
      recommendations: _generateRecommendations(dominantMood, positiveRatio),
      improvementScore: improvementScore.clamp(0.0, 100.0),
      achievements: _calculateAchievements(entries),
      dominantMood: dominantMood,
      positiveRatio: positiveRatio,
      negativeRatio: negativeRatio,
    );
  }

  // 私有方法用于计算趋势和模式
  static List<MoodTrendPoint> _calculateDailyTrend(List<MoodEntry> entries) {
    // 简化实现，返回最近7天的趋势
    final trends = <MoodTrendPoint>[];
    final now = DateTime.now();

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dayEntries = entries.where((e) =>
        e.timestamp.year == date.year &&
        e.timestamp.month == date.month &&
        e.timestamp.day == date.day
      ).toList();

      final avgIntensity = dayEntries.isEmpty ? 0.0 :
        dayEntries.map((e) => e.intensity).reduce((a, b) => a + b) / dayEntries.length;

      trends.add(MoodTrendPoint(
        date: date,
        averageIntensity: avgIntensity,
        entryCount: dayEntries.length,
      ));
    }

    return trends;
  }

  static List<MoodTrendPoint> _calculateWeeklyTrend(List<MoodEntry> entries) {
    // 简化实现
    return [];
  }

  static List<MoodTrendPoint> _calculateMonthlyTrend(List<MoodEntry> entries) {
    // 简化实现
    return [];
  }

  static List<MoodPattern> _identifyPatterns(List<MoodEntry> entries) {
    // 简化实现
    return [];
  }

  static List<String> _generateInsights(List<MoodEntry> entries, double positiveRatio, double negativeRatio) {
    final insights = <String>[];

    if (positiveRatio > 0.7) {
      insights.add('你最近的心情状态很棒！保持积极的生活态度。');
    } else if (negativeRatio > 0.5) {
      insights.add('最近可能遇到了一些挑战，记得照顾好自己的情绪。');
    }

    if (entries.any((e) => e.gratitude.isNotEmpty)) {
      insights.add('感恩记录让你的心情更加积极，继续保持这个好习惯！');
    }

    return insights;
  }

  static List<String> _generateRecommendations(MoodType dominantMood, double positiveRatio) {
    final recommendations = <String>[];

    if (positiveRatio < 0.3) {
      recommendations.add('尝试每天记录三件感恩的事情');
      recommendations.add('增加户外活动和运动时间');
      recommendations.add('与朋友和家人保持联系');
    }

    if (dominantMood == MoodType.stressed) {
      recommendations.add('尝试深呼吸和冥想练习');
      recommendations.add('合理安排工作和休息时间');
    }

    return recommendations;
  }

  static List<Achievement> _calculateAchievements(List<MoodEntry> entries) {
    final achievements = <Achievement>[];

    if (entries.length >= 7) {
      achievements.add(Achievement(
        id: 'week_recorder',
        title: '坚持记录一周',
        description: '连续记录心情一周，养成好习惯！',
        icon: '📝',
        unlockedAt: DateTime.now(),
      ));
    }

    final gratitudeCount = entries.where((e) => e.gratitude.isNotEmpty).length;
    if (gratitudeCount >= 10) {
      achievements.add(Achievement(
        id: 'gratitude_master',
        title: '感恩达人',
        description: '记录了10次感恩，心怀感激！',
        icon: '🙏',
        unlockedAt: DateTime.now(),
      ));
    }

    return achievements;
  }
}

/// 心情趋势点
class MoodTrendPoint {
  final DateTime date;
  final double averageIntensity;
  final int entryCount;

  MoodTrendPoint({
    required this.date,
    required this.averageIntensity,
    required this.entryCount,
  });
}

/// 心情模式
class MoodPattern {
  final String id;
  final String name;
  final String description;
  final List<MoodType> moodSequence;
  final double confidence;

  MoodPattern({
    required this.id,
    required this.name,
    required this.description,
    required this.moodSequence,
    required this.confidence,
  });
}

/// 成就
class Achievement {
  final String id;
  final String title;
  final String description;
  final String icon;
  final DateTime unlockedAt;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.unlockedAt,
  });
}
