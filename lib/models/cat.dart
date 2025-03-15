import 'package:flutter/material.dart';

/// 猫咪品种枚举
enum CatBreed {
  persian,    // 波斯猫
  ragdoll,    // 布偶猫
  siamese,    // 暹罗猫
  bengal,     // 孟加拉猫
  maineCoon,  // 缅因猫
  random      // 随机猫
}

/// 猫咪心情状态枚举
enum CatMoodState {
  happy,   // 开心
  normal,  // 普通
  hungry,  // 饿了
  tired,   // 疲惫
  bored    // 无聊
}

/// 猫咪成长阶段枚举
enum CatGrowthStage {
  kitten,    // 幼猫
  juvenile,  // 少年猫
  adult      // 成年猫
}

/// 猫咪模型类
class Cat {
  String name;
  final CatBreed breed;
  CatMoodState mood;
  CatGrowthStage growthStage;
  int energyLevel;
  int happiness;
  DateTime lastFedTime;
  DateTime lastPlayTime;
  DateTime lastGroomTime;
  DateTime lastTrainingTime;
  final Map<String, String> equippedAccessories;
  
  // 互动次数统计
  int petCount = 0;
  int feedCount = 0;
  int playCount = 0;
  int groomCount = 0;
  int trainingCount = 0;
  
  // 互动技能等级
  int playSkill = 1;
  int trainingSkill = 1;
  
  // 互动冷却时间（秒）
  static const int feedCooldown = 3600; // 1小时
  static const int playCooldown = 1800; // 30分钟
  static const int groomCooldown = 43200; // 12小时
  static const int trainingCooldown = 7200; // 2小时

  Cat({
    required this.name,
    required this.breed,
    this.mood = CatMoodState.normal,
    this.growthStage = CatGrowthStage.kitten,
    this.energyLevel = 100,
    this.happiness = 50,
    DateTime? lastFedTime,
    DateTime? lastPlayTime,
    DateTime? lastGroomTime,
    DateTime? lastTrainingTime,
    Map<String, String>? equippedAccessories,
    this.petCount = 0,
    this.feedCount = 0,
    this.playCount = 0,
    this.groomCount = 0,
    this.trainingCount = 0,
    this.playSkill = 1,
    this.trainingSkill = 1,
  }) : 
    lastFedTime = lastFedTime ?? DateTime.now(),
    lastPlayTime = lastPlayTime ?? DateTime.now(),
    lastGroomTime = lastGroomTime ?? DateTime.now(),
    lastTrainingTime = lastTrainingTime ?? DateTime.now(),
    equippedAccessories = equippedAccessories ?? {};

  /// 将猫咪转换为JSON格式
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'breed': breed.toString().split('.').last,
      'mood': mood.toString().split('.').last,
      'growthStage': growthStage.toString().split('.').last,
      'energyLevel': energyLevel,
      'happiness': happiness,
      'lastFedTime': lastFedTime.toIso8601String(),
      'lastPlayTime': lastPlayTime.toIso8601String(),
      'lastGroomTime': lastGroomTime.toIso8601String(),
      'lastTrainingTime': lastTrainingTime.toIso8601String(),
      'equippedAccessories': equippedAccessories,
      'petCount': petCount,
      'feedCount': feedCount,
      'playCount': playCount,
      'groomCount': groomCount,
      'trainingCount': trainingCount,
      'playSkill': playSkill,
      'trainingSkill': trainingSkill,
    };
  }

  /// 从JSON创建猫咪
  factory Cat.fromJson(Map<String, dynamic> json) {
    return Cat(
      name: json['name'],
      breed: _breedFromString(json['breed']),
      mood: _moodFromString(json['mood']),
      growthStage: _growthStageFromString(json['growthStage']),
      energyLevel: json['energyLevel'],
      happiness: json['happiness'],
      lastFedTime: DateTime.parse(json['lastFedTime']),
      lastPlayTime: DateTime.parse(json['lastPlayTime']),
      lastGroomTime: json['lastGroomTime'] != null ? DateTime.parse(json['lastGroomTime']) : null,
      lastTrainingTime: json['lastTrainingTime'] != null ? DateTime.parse(json['lastTrainingTime']) : null,
      equippedAccessories: Map<String, String>.from(json['equippedAccessories']),
      petCount: json['petCount'] ?? 0,
      feedCount: json['feedCount'] ?? 0,
      playCount: json['playCount'] ?? 0,
      groomCount: json['groomCount'] ?? 0,
      trainingCount: json['trainingCount'] ?? 0,
      playSkill: json['playSkill'] ?? 1,
      trainingSkill: json['trainingSkill'] ?? 1,
    );
  }

  /// 从字符串转换为品种枚举
  static CatBreed _breedFromString(String breedStr) {
    return CatBreed.values.firstWhere(
      (e) => e.toString().split('.').last == breedStr,
      orElse: () => CatBreed.random,
    );
  }

  /// 从字符串转换为心情枚举
  static CatMoodState _moodFromString(String moodStr) {
    return CatMoodState.values.firstWhere(
      (e) => e.toString().split('.').last == moodStr,
      orElse: () => CatMoodState.normal,
    );
  }

  /// 从字符串转换为成长阶段枚举
  static CatGrowthStage _growthStageFromString(String stageStr) {
    return CatGrowthStage.values.firstWhere(
      (e) => e.toString().split('.').last == stageStr,
      orElse: () => CatGrowthStage.kitten,
    );
  }

  /// 获取猫咪品种颜色
  Color get breedColor {
    switch (breed) {
      case CatBreed.persian:
        return Colors.grey.shade200;
      case CatBreed.ragdoll:
        return Colors.blue.shade100;
      case CatBreed.siamese:
        return Colors.brown.shade200;
      case CatBreed.bengal:
        return Colors.orange.shade200;
      case CatBreed.maineCoon:
        return Colors.brown.shade300;
      case CatBreed.random:
        return Colors.teal.shade100;
    }
  }

  /// 获取心情文本
  String get moodText {
    switch (mood) {
      case CatMoodState.happy:
        return '开心';
      case CatMoodState.normal:
        return '平静';
      case CatMoodState.hungry:
        return '饥饿';
      case CatMoodState.tired:
        return '疲惫';
      case CatMoodState.bored:
        return '无聊';
    }
  }

  /// 获取成长阶段文本
  String get growthStageText {
    switch (growthStage) {
      case CatGrowthStage.kitten:
        return '幼猫期';
      case CatGrowthStage.juvenile:
        return '少年期';
      case CatGrowthStage.adult:
        return '成年期';
    }
  }

  /// 喂食
  void feed() {
    energyLevel = _clamp(energyLevel + 20, 0, 100);
    happiness = _clamp(happiness + 10, 0, 100);
    lastFedTime = DateTime.now();
    feedCount++;
    _updateMood();
  }

  /// 抚摸
  void pet() {
    happiness = _clamp(happiness + 5, 0, 100);
    petCount++;
    _updateMood();
  }

  /// 玩耍
  void play() {
    // 根据技能等级增加效果
    final happinessIncrease = 10 + (playSkill * 2);
    final energyDecrease = 10 - (playSkill ~/ 2);
    
    happiness = _clamp(happiness + happinessIncrease, 0, 100);
    energyLevel = _clamp(energyLevel - energyDecrease, 0, 100);
    lastPlayTime = DateTime.now();
    playCount++;
    
    // 有几率提升玩耍技能
    if (playCount % 5 == 0 && playSkill < 10) {
      playSkill++;
    }
    
    _updateMood();
  }
  
  /// 洗澡/梳理
  void groom() {
    happiness = _clamp(happiness + 8, 0, 100);
    lastGroomTime = DateTime.now();
    groomCount++;
    _updateMood();
  }
  
  /// 训练
  void train() {
    // 根据技能等级增加效果
    final happinessIncrease = 5 + trainingSkill;
    final energyDecrease = 15 - (trainingSkill ~/ 2);
    
    happiness = _clamp(happiness + happinessIncrease, 0, 100);
    energyLevel = _clamp(energyLevel - energyDecrease, 0, 100);
    lastTrainingTime = DateTime.now();
    trainingCount++;
    
    // 有几率提升训练技能
    if (trainingCount % 3 == 0 && trainingSkill < 10) {
      trainingSkill++;
    }
    
    _updateMood();
  }

  /// 检查喂食冷却状态
  bool get canFeed {
    return DateTime.now().difference(lastFedTime).inSeconds >= feedCooldown;
  }
  
  /// 检查玩耍冷却状态
  bool get canPlay {
    return DateTime.now().difference(lastPlayTime).inSeconds >= playCooldown;
  }
  
  /// 检查洗澡冷却状态
  bool get canGroom {
    return DateTime.now().difference(lastGroomTime).inSeconds >= groomCooldown;
  }
  
  /// 检查训练冷却状态
  bool get canTrain {
    return DateTime.now().difference(lastTrainingTime).inSeconds >= trainingCooldown;
  }
  
  /// 获取喂食剩余冷却时间（秒）
  int get feedCooldownRemaining {
    final diff = feedCooldown - DateTime.now().difference(lastFedTime).inSeconds;
    return diff > 0 ? diff : 0;
  }
  
  /// 获取玩耍剩余冷却时间（秒）
  int get playCooldownRemaining {
    final diff = playCooldown - DateTime.now().difference(lastPlayTime).inSeconds;
    return diff > 0 ? diff : 0;
  }
  
  /// 获取洗澡剩余冷却时间（秒）
  int get groomCooldownRemaining {
    final diff = groomCooldown - DateTime.now().difference(lastGroomTime).inSeconds;
    return diff > 0 ? diff : 0;
  }
  
  /// 获取训练剩余冷却时间（秒）
  int get trainingCooldownRemaining {
    final diff = trainingCooldown - DateTime.now().difference(lastTrainingTime).inSeconds;
    return diff > 0 ? diff : 0;
  }

  /// 更新心情状态
  void _updateMood() {
    if (happiness > 80) {
      mood = CatMoodState.happy;
    } else if (energyLevel < 30) {
      mood = CatMoodState.tired;
    } else if (_isHungry()) {
      mood = CatMoodState.hungry;
    } else if (happiness < 30) {
      mood = CatMoodState.bored;
    } else {
      mood = CatMoodState.normal;
    }
  }

  /// 检查是否饥饿
  bool _isHungry() {
    final hoursSinceLastMeal = DateTime.now().difference(lastFedTime).inHours;
    return hoursSinceLastMeal >= 4;
  }

  /// 限制数值范围
  int _clamp(int value, int min, int max) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }

  /// 更新状态（随时间流逝）
  void updateStatus() {
    final hoursSinceLastMeal = DateTime.now().difference(lastFedTime).inHours;
    final hoursSinceLastPlay = DateTime.now().difference(lastPlayTime).inHours;
    
    // 每4小时能量减少10
    if (hoursSinceLastMeal > 0) {
      energyLevel = _clamp(energyLevel - hoursSinceLastMeal * 10 ~/ 4, 0, 100);
    }
    
    // 每2小时快乐度减少5
    if (hoursSinceLastPlay > 0) {
      happiness = _clamp(happiness - hoursSinceLastPlay * 5 ~/ 2, 0, 100);
    }
    
    _updateMood();
  }
} 