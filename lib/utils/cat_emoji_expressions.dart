import '../models/cat.dart';
import '../widgets/cat_interaction_animation.dart';

/// 猫咪表情emoji工具类
class CatEmojiExpressions {
  /// 根据猫咪心情状态获取对应的emoji表情
  static String getMoodEmoji(CatMoodState mood) {
    switch (mood) {
      case CatMoodState.happy:
        return '😸'; // 开心的猫咪
      case CatMoodState.normal:
        return '😺'; // 普通的猫咪
      case CatMoodState.hungry:
        return '😿'; // 饥饿的猫咪
      case CatMoodState.tired:
        return '😴'; // 疲惫的猫咪
      case CatMoodState.bored:
        return '😾'; // 无聊的猫咪
    }
  }

  /// 根据互动类型获取反馈emoji
  static String getInteractionEmoji(
      InteractionAnimationType type, CatMoodState mood) {
    switch (type) {
      case InteractionAnimationType.pet:
        return _getPetEmoji(mood);
      case InteractionAnimationType.feed:
        return _getFeedEmoji(mood);
      case InteractionAnimationType.play:
        return _getPlayEmoji(mood);
      case InteractionAnimationType.groom:
        return _getGroomEmoji(mood);
      case InteractionAnimationType.train:
        return _getTrainEmoji(mood);
    }
  }

  /// 获取抚摸反馈emoji
  static String _getPetEmoji(CatMoodState mood) {
    switch (mood) {
      case CatMoodState.happy:
        return '😻'; // 爱心眼猫咪
      case CatMoodState.normal:
        return '😊'; // 微笑
      case CatMoodState.hungry:
        return '🤗'; // 拥抱
      case CatMoodState.tired:
        return '😌'; // 安心
      case CatMoodState.bored:
        return '😸'; // 开心
    }
  }

  /// 获取喂食反馈emoji
  static String _getFeedEmoji(CatMoodState mood) {
    switch (mood) {
      case CatMoodState.happy:
        return '😋'; // 美味
      case CatMoodState.normal:
        return '😋'; // 美味
      case CatMoodState.hungry:
        return '🤤'; // 流口水
      case CatMoodState.tired:
        return '😋'; // 美味
      case CatMoodState.bored:
        return '😋'; // 美味
    }
  }

  /// 获取玩耍反馈emoji
  static String _getPlayEmoji(CatMoodState mood) {
    switch (mood) {
      case CatMoodState.happy:
        return '🎉'; // 庆祝
      case CatMoodState.normal:
        return '🎾'; // 玩球
      case CatMoodState.hungry:
        return '😅'; // 勉强玩耍
      case CatMoodState.tired:
        return '😪'; // 困倦
      case CatMoodState.bored:
        return '🎯'; // 兴奋玩耍
    }
  }

  /// 获取梳理反馈emoji
  static String _getGroomEmoji(CatMoodState mood) {
    switch (mood) {
      case CatMoodState.happy:
        return '✨'; // 闪亮
      case CatMoodState.normal:
        return '🧼'; // 清洁
      case CatMoodState.hungry:
        return '😌'; // 安心
      case CatMoodState.tired:
        return '💆'; // 按摩
      case CatMoodState.bored:
        return '✨'; // 闪亮
    }
  }

  /// 获取训练反馈emoji
  static String _getTrainEmoji(CatMoodState mood) {
    switch (mood) {
      case CatMoodState.happy:
        return '🌟'; // 星星
      case CatMoodState.normal:
        return '🎓'; // 学习
      case CatMoodState.hungry:
        return '🤔'; // 思考
      case CatMoodState.tired:
        return '😵'; // 晕眩
      case CatMoodState.bored:
        return '💪'; // 努力
    }
  }

  /// 获取长时间不互动的想念表情
  static String getLonelyEmoji() {
    return '💭'; // 思考泡泡
  }

  /// 获取互动频繁时的满足表情
  static String getSatisfiedEmoji() {
    return '❤️'; // 爱心
  }

  /// 获取冷却中的等待表情
  static String getCooldownEmoji() {
    return '⏰'; // 时钟
  }

  /// 获取随机开心表情
  static String getRandomHappyEmoji() {
    final happyEmojis = [
      '😸',
      '😻',
      '🥰',
      '😊',
      '❤️',
      '💕',
      '🎉',
      '✨',
      '🌟',
      '💖'
    ];
    happyEmojis.shuffle();
    return happyEmojis.first;
  }

  /// 获取随机关心表情
  static String getRandomCareEmoji() {
    final careEmojis = ['🤗', '💕', '😌', '🥺', '💖', '🫂', '💝', '🤲'];
    careEmojis.shuffle();
    return careEmojis.first;
  }

  /// 获取基于时间的动态表情
  static String getTimeBasedEmoji() {
    final hour = DateTime.now().hour;
    if (hour >= 6 && hour < 12) {
      return '🌅'; // 早晨
    } else if (hour >= 12 && hour < 18) {
      return '☀️'; // 下午
    } else if (hour >= 18 && hour < 22) {
      return '🌆'; // 傍晚
    } else {
      return '🌙'; // 夜晚
    }
  }

  /// 获取连击表情（连续互动时显示）
  static String getComboEmoji(int comboCount) {
    if (comboCount >= 5) {
      return '🔥'; // 火热连击
    } else if (comboCount >= 3) {
      return '⚡'; // 闪电连击
    } else if (comboCount >= 2) {
      return '💫'; // 星光连击
    }
    return '✨'; // 普通连击
  }

  /// 根据互动频率获取特殊表情
  static String getFrequencyBasedEmoji(Cat cat) {
    final now = DateTime.now();
    final totalInteractions = cat.petCount +
        cat.feedCount +
        cat.playCount +
        cat.groomCount +
        cat.trainingCount;

    // 检查最近1小时的互动频率
    final recentInteractions = _getRecentInteractionCount(cat, now);

    if (recentInteractions >= 10) {
      return '🥰'; // 非常满足
    } else if (recentInteractions >= 5) {
      return '😸'; // 开心
    } else if (totalInteractions == 0) {
      return '🥺'; // 期待互动
    } else if (_getHoursSinceLastInteraction(cat, now) > 6) {
      return '💭'; // 想念主人
    }

    return getMoodEmoji(cat.mood);
  }

  /// 获取最近互动次数（简化版本，基于总互动次数估算）
  static int _getRecentInteractionCount(Cat cat, DateTime now) {
    // 简化实现：基于当前心情和总互动次数估算
    final totalInteractions = cat.petCount +
        cat.feedCount +
        cat.playCount +
        cat.groomCount +
        cat.trainingCount;

    if (cat.mood == CatMoodState.happy && totalInteractions > 20) {
      return 8; // 估算最近互动较多
    } else if (cat.mood == CatMoodState.normal && totalInteractions > 10) {
      return 3; // 估算最近互动适中
    }

    return 1; // 估算最近互动较少
  }

  /// 获取距离上次互动的小时数
  static int _getHoursSinceLastInteraction(Cat cat, DateTime now) {
    final lastInteractionTimes = [
      cat.lastFedTime,
      cat.lastPlayTime,
      cat.lastGroomTime,
      cat.lastTrainingTime,
    ];

    // 找到最近的互动时间
    DateTime? mostRecentInteraction;
    for (final time in lastInteractionTimes) {
      if (mostRecentInteraction == null ||
          time.isAfter(mostRecentInteraction)) {
        mostRecentInteraction = time;
      }
    }

    if (mostRecentInteraction != null) {
      return now.difference(mostRecentInteraction).inHours;
    }

    return 0;
  }

  /// 获取基于能量和快乐度的组合表情
  static String getStatusBasedEmoji(Cat cat) {
    if (cat.happiness > 80 && cat.energyLevel > 70) {
      return '🌟'; // 完美状态
    } else if (cat.happiness > 60 && cat.energyLevel < 30) {
      return '😴'; // 开心但疲惫
    } else if (cat.happiness < 30 && cat.energyLevel > 70) {
      return '😾'; // 有精力但不开心
    } else if (cat.happiness < 30 && cat.energyLevel < 30) {
      return '😿'; // 双重低落
    }

    return getMoodEmoji(cat.mood);
  }

  /// 获取长时间不互动时的想念表情序列
  static List<String> getLonelyEmojiSequence() {
    return ['😔', '💭', '🥺', '😿', '💔'];
  }

  /// 获取互动频繁时的满足表情序列
  static List<String> getSatisfiedEmojiSequence() {
    return ['😊', '😸', '🥰', '❤️', '💖', '✨'];
  }

  /// 获取特殊状态组合的emoji表情
  static String getSpecialStatusEmoji(Cat cat) {
    final happiness = cat.happiness;
    final energy = cat.energyLevel;

    // 完美状态
    if (happiness >= 90 && energy >= 80) {
      return '🌟';
    }
    // 非常开心但疲惫
    else if (happiness >= 80 && energy <= 20) {
      return '😴';
    }
    // 有精力但不开心
    else if (happiness <= 30 && energy >= 70) {
      return '😾';
    }
    // 双重低落
    else if (happiness <= 30 && energy <= 30) {
      return '😿';
    }
    // 中等状态但饥饿
    else if (cat.mood == CatMoodState.hungry) {
      return '🍽️';
    }

    return getMoodEmoji(cat.mood);
  }

  /// 获取互动连击表情
  static String getInteractionComboEmoji(int comboCount) {
    if (comboCount >= 10) {
      return '🔥'; // 超级连击
    } else if (comboCount >= 7) {
      return '⚡'; // 闪电连击
    } else if (comboCount >= 5) {
      return '💫'; // 星光连击
    } else if (comboCount >= 3) {
      return '✨'; // 普通连击
    }
    return '💕'; // 基础互动
  }

  /// 获取增强的互动反馈emoji（考虑连击和特殊状态）
  static String getEnhancedInteractionEmoji(
      InteractionAnimationType type, Cat cat, int comboCount) {
    // 如果有连击，优先显示连击表情
    if (comboCount >= 3) {
      return getInteractionComboEmoji(comboCount);
    }

    // 根据猫咪特殊状态调整表情
    final specialEmoji = getSpecialStatusEmoji(cat);
    if (specialEmoji != getMoodEmoji(cat.mood)) {
      return specialEmoji;
    }

    // 否则使用标准互动表情
    return getInteractionEmoji(type, cat.mood);
  }

  /// 获取互动成功的庆祝emoji序列
  static List<String> getCelebrationEmojiSequence() {
    return ['🎉', '✨', '🌟', '💫', '🎊', '🥳'];
  }

  /// 获取基于时间段的问候emoji
  static String getGreetingEmoji() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return '🌅'; // 早安
    } else if (hour >= 12 && hour < 17) {
      return '☀️'; // 午安
    } else if (hour >= 17 && hour < 21) {
      return '🌆'; // 晚安
    } else {
      return '🌙'; // 夜安
    }
  }

  /// 获取互动反馈的动态emoji（带有随机性）
  static String getDynamicInteractionEmoji(
      InteractionAnimationType type, Cat cat) {
    final random = DateTime.now().millisecond % 3;

    switch (type) {
      case InteractionAnimationType.pet:
        final petEmojis = ['😻', '🥰', '💕', '😊', '🤗'];
        return petEmojis[random % petEmojis.length];
      case InteractionAnimationType.feed:
        final feedEmojis = ['😋', '🤤', '😍', '🍽️', '🥛'];
        return feedEmojis[random % feedEmojis.length];
      case InteractionAnimationType.play:
        final playEmojis = ['🎾', '🎯', '🎪', '🎭', '🎨'];
        return playEmojis[random % playEmojis.length];
      case InteractionAnimationType.groom:
        final groomEmojis = ['✨', '🧼', '💆', '🛁', '🌟'];
        return groomEmojis[random % groomEmojis.length];
      case InteractionAnimationType.train:
        final trainEmojis = ['🎓', '🏆', '💪', '🌟', '⭐'];
        return trainEmojis[random % trainEmojis.length];
    }
  }

  /// 获取心情变化过渡表情
  static String getMoodTransitionEmoji(
      CatMoodState fromMood, CatMoodState toMood) {
    // 从不好的心情变好
    if ((fromMood == CatMoodState.hungry ||
            fromMood == CatMoodState.tired ||
            fromMood == CatMoodState.bored) &&
        (toMood == CatMoodState.happy || toMood == CatMoodState.normal)) {
      return '🌈'; // 彩虹表示心情转好
    }
    // 从好心情变差
    else if ((fromMood == CatMoodState.happy ||
            fromMood == CatMoodState.normal) &&
        (toMood == CatMoodState.hungry ||
            toMood == CatMoodState.tired ||
            toMood == CatMoodState.bored)) {
      return '☁️'; // 云朵表示心情变差
    }

    return getMoodEmoji(toMood);
  }
}
