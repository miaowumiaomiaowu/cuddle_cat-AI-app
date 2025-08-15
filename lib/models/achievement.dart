import 'package:flutter/material.dart';

enum AchievementType {
  streak,        // 连续完成
  category,      // 分类专精
  social,        // 社交突破
  creativity,    // 创作成就
  wellness,      // 健康生活
  milestone,     // 里程碑
  special        // 特殊成就
}

enum AchievementTier {
  bronze,   // 铜牌
  silver,   // 银牌
  gold,     // 金牌
  platinum, // 白金
  diamond   // 钻石
}

class Achievement {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final AchievementType type;
  final AchievementTier tier;
  final int requiredValue;
  final DateTime? unlockedAt;
  final bool isUnlocked;
  final int currentProgress;
  final Map<String, dynamic>? metadata;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.type,
    required this.tier,
    required this.requiredValue,
    this.unlockedAt,
    this.isUnlocked = false,
    this.currentProgress = 0,
    this.metadata,
  });

  double get progressPercentage => 
      requiredValue > 0 ? (currentProgress / requiredValue).clamp(0.0, 1.0) : 0.0;

  Color get tierColor {
    switch (tier) {
      case AchievementTier.bronze:
        return const Color(0xFFCD7F32);
      case AchievementTier.silver:
        return const Color(0xFFC0C0C0);
      case AchievementTier.gold:
        return const Color(0xFFFFD700);
      case AchievementTier.platinum:
        return const Color(0xFFE5E4E2);
      case AchievementTier.diamond:
        return const Color(0xFFB9F2FF);
    }
  }

  String get tierName {
    switch (tier) {
      case AchievementTier.bronze:
        return '铜牌';
      case AchievementTier.silver:
        return '银牌';
      case AchievementTier.gold:
        return '金牌';
      case AchievementTier.platinum:
        return '白金';
      case AchievementTier.diamond:
        return '钻石';
    }
  }

  Achievement copyWith({
    String? id,
    String? title,
    String? description,
    String? emoji,
    AchievementType? type,
    AchievementTier? tier,
    int? requiredValue,
    DateTime? unlockedAt,
    bool? isUnlocked,
    int? currentProgress,
    Map<String, dynamic>? metadata,
  }) {
    return Achievement(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      emoji: emoji ?? this.emoji,
      type: type ?? this.type,
      tier: tier ?? this.tier,
      requiredValue: requiredValue ?? this.requiredValue,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      currentProgress: currentProgress ?? this.currentProgress,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'emoji': emoji,
    'type': type.name,
    'tier': tier.name,
    'requiredValue': requiredValue,
    'unlockedAt': unlockedAt?.toIso8601String(),
    'isUnlocked': isUnlocked,
    'currentProgress': currentProgress,
    'metadata': metadata,
  };

  factory Achievement.fromJson(Map<String, dynamic> json) => Achievement(
    id: json['id'] as String,
    title: json['title'] as String,
    description: json['description'] as String,
    emoji: json['emoji'] as String,
    type: AchievementType.values.firstWhere((e) => e.name == json['type']),
    tier: AchievementTier.values.firstWhere((e) => e.name == json['tier']),
    requiredValue: json['requiredValue'] as int,
    unlockedAt: json['unlockedAt'] != null ? DateTime.parse(json['unlockedAt']) : null,
    isUnlocked: json['isUnlocked'] as bool? ?? false,
    currentProgress: json['currentProgress'] as int? ?? 0,
    metadata: json['metadata'] as Map<String, dynamic>?,
  );
}

// 预定义成就模板
class AchievementTemplates {
  static List<Achievement> get defaultAchievements => [
    // 连续完成成就
    Achievement(
      id: 'streak_3',
      title: '初心不改',
      description: '连续3天完成幸福任务',
      emoji: '🔥',
      type: AchievementType.streak,
      tier: AchievementTier.bronze,
      requiredValue: 3,
    ),
    Achievement(
      id: 'streak_7',
      title: '一周坚持',
      description: '连续7天完成幸福任务',
      emoji: '⭐',
      type: AchievementType.streak,
      tier: AchievementTier.silver,
      requiredValue: 7,
    ),
    Achievement(
      id: 'streak_30',
      title: '月度达人',
      description: '连续30天完成幸福任务',
      emoji: '👑',
      type: AchievementType.streak,
      tier: AchievementTier.gold,
      requiredValue: 30,
    ),
    
    // 分类专精成就
    Achievement(
      id: 'category_relax_10',
      title: '放松大师',
      description: '完成10个放松类任务',
      emoji: '🧘‍♀️',
      type: AchievementType.category,
      tier: AchievementTier.bronze,
      requiredValue: 10,
      metadata: {'category': '放松'},
    ),
    Achievement(
      id: 'category_exercise_15',
      title: '运动健将',
      description: '完成15个运动类任务',
      emoji: '💪',
      type: AchievementType.category,
      tier: AchievementTier.silver,
      requiredValue: 15,
      metadata: {'category': '运动'},
    ),
    
    // 社交突破成就
    Achievement(
      id: 'social_first',
      title: '社交新星',
      description: '完成第一个社交类任务',
      emoji: '🌟',
      type: AchievementType.social,
      tier: AchievementTier.bronze,
      requiredValue: 1,
    ),
    Achievement(
      id: 'social_breakthrough',
      title: '社交达人',
      description: '克服社交恐惧，主动与人交流',
      emoji: '🎭',
      type: AchievementType.social,
      tier: AchievementTier.gold,
      requiredValue: 1,
    ),
    
    // 创作成就
    Achievement(
      id: 'creativity_first',
      title: '创作萌芽',
      description: '完成第一个创作类任务',
      emoji: '🎨',
      type: AchievementType.creativity,
      tier: AchievementTier.bronze,
      requiredValue: 1,
    ),
    
    // 健康生活成就
    Achievement(
      id: 'wellness_sleep',
      title: '早睡早起',
      description: '连续7天保持良好作息',
      emoji: '😴',
      type: AchievementType.wellness,
      tier: AchievementTier.silver,
      requiredValue: 7,
    ),
    
    // 里程碑成就
    Achievement(
      id: 'milestone_100',
      title: '百日筑梦',
      description: '累计完成100个幸福任务',
      emoji: '💎',
      type: AchievementType.milestone,
      tier: AchievementTier.diamond,
      requiredValue: 100,
    ),
    
    // 特殊成就
    Achievement(
      id: 'special_first_gift',
      title: '初次相遇',
      description: '第一次开启幸福礼物',
      emoji: '🎁',
      type: AchievementType.special,
      tier: AchievementTier.bronze,
      requiredValue: 1,
    ),
  ];
}
