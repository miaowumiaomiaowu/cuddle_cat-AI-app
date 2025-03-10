import 'package:flutter/material.dart';

/// 猫咪成长阶段
enum CatGrowthStage {
  baby, // 幼猫期
  juvenile, // 青少年期
  adult, // 成年期
}

/// 猫咪心情状态
enum CatMoodState {
  happy, // 开心
  normal, // 正常
  hungry, // 饥饿
  tired, // 疲惫
  bored, // 无聊
}

/// 猫咪品种
enum CatBreed {
  persian, // 波斯猫
  ragdoll, // 布偶猫
  siamese, // 暹罗猫
  bengal, // 孟加拉猫
  maineCoon, // 缅因猫
  random, // 随机混血猫
}

/// 猫咪实体类
class Cat {
  final String id; // 唯一ID
  String name; // 猫咪名字
  final CatBreed breed; // 猫咪品种
  final DateTime adoptionDate; // 领养日期
  
  int experiencePoints; // 经验值
  CatGrowthStage growthStage; // 成长阶段
  CatMoodState mood; // 当前心情
  
  int energyLevel; // 能量等级 (0-100)
  int affectionLevel; // 亲密度 (0-100)
  
  List<String> unlockedAccessories; // 已解锁的装饰品
  Map<String, String> equippedAccessories; // 当前穿戴的装饰品 {类型: ID}
  
  // 构造函数
  Cat({
    required this.id,
    required this.name,
    required this.breed,
    required this.adoptionDate,
    this.experiencePoints = 0,
    this.growthStage = CatGrowthStage.baby,
    this.mood = CatMoodState.normal,
    this.energyLevel = 80,
    this.affectionLevel = 50,
    List<String>? unlockedAccessories,
    Map<String, String>? equippedAccessories,
  }) : 
    unlockedAccessories = unlockedAccessories ?? [],
    equippedAccessories = equippedAccessories ?? {};
  
  // 获取成长阶段的显示文本
  String get growthStageText {
    switch (growthStage) {
      case CatGrowthStage.baby:
        return '幼猫期';
      case CatGrowthStage.juvenile:
        return '青少年期';
      case CatGrowthStage.adult:
        return '成年期';
    }
  }
  
  // 获取心情状态的显示文本
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
  
  // 获取品种的显示文本
  String get breedText {
    switch (breed) {
      case CatBreed.persian:
        return '波斯猫';
      case CatBreed.ragdoll:
        return '布偶猫';
      case CatBreed.siamese:
        return '暹罗猫';
      case CatBreed.bengal:
        return '孟加拉猫';
      case CatBreed.maineCoon:
        return '缅因猫';
      case CatBreed.random:
        return '混血猫';
    }
  }
  
  // 获取品种对应的主要颜色
  Color get breedColor {
    switch (breed) {
      case CatBreed.persian:
        return Colors.grey.shade300;
      case CatBreed.ragdoll:
        return Colors.blue.shade100;
      case CatBreed.siamese:
        return Colors.brown.shade300;
      case CatBreed.bengal:
        return Colors.orange.shade300;
      case CatBreed.maineCoon:
        return Colors.brown.shade700;
      case CatBreed.random:
        return Colors.pink.shade200;
    }
  }
  
  // 增加经验值并检查是否升级
  void addExperience(int amount) {
    experiencePoints += amount;
    _checkLevelUp();
  }
  
  // 检查是否可以升级成长阶段
  void _checkLevelUp() {
    if (growthStage == CatGrowthStage.baby && experiencePoints >= 1000) {
      growthStage = CatGrowthStage.juvenile;
    } else if (growthStage == CatGrowthStage.juvenile && experiencePoints >= 3000) {
      growthStage = CatGrowthStage.adult;
    }
  }
  
  // 喂食
  void feed() {
    energyLevel = (energyLevel + 20).clamp(0, 100);
    if (mood == CatMoodState.hungry) {
      mood = CatMoodState.normal;
    }
    addExperience(5);
  }
  
  // 抚摸
  void pet() {
    affectionLevel = (affectionLevel + 5).clamp(0, 100);
    if (affectionLevel > 80) {
      mood = CatMoodState.happy;
    }
    addExperience(2);
  }
  
  // 玩耍
  void play() {
    energyLevel = (energyLevel - 10).clamp(0, 100);
    affectionLevel = (affectionLevel + 10).clamp(0, 100);
    mood = CatMoodState.happy;
    addExperience(10);
  }
  
  // 装扮猫咪
  void equip(String accessoryType, String accessoryId) {
    if (unlockedAccessories.contains(accessoryId)) {
      equippedAccessories[accessoryType] = accessoryId;
    }
  }
  
  // 解锁新装饰品
  void unlockAccessory(String accessoryId) {
    if (!unlockedAccessories.contains(accessoryId)) {
      unlockedAccessories.add(accessoryId);
      addExperience(20);
    }
  }
  
  // 模拟时间流逝对猫咪状态的影响
  void simulateTimePassage(Duration elapsed) {
    // 能量随时间流逝而降低
    final hoursElapsed = elapsed.inHours;
    if (hoursElapsed > 0) {
      energyLevel = (energyLevel - hoursElapsed * 2).clamp(0, 100);
      
      // 更新心情状态
      if (energyLevel < 20) {
        mood = CatMoodState.hungry;
      } else if (affectionLevel < 30) {
        mood = CatMoodState.bored;
      } else if (mood == CatMoodState.happy && affectionLevel < 70) {
        mood = CatMoodState.normal;
      }
    }
  }
  
  // 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'breed': breed.index,
      'adoptionDate': adoptionDate.toIso8601String(),
      'experiencePoints': experiencePoints,
      'growthStage': growthStage.index,
      'mood': mood.index,
      'energyLevel': energyLevel,
      'affectionLevel': affectionLevel,
      'unlockedAccessories': unlockedAccessories,
      'equippedAccessories': equippedAccessories,
    };
  }
  
  // 从JSON创建猫咪实例
  factory Cat.fromJson(Map<String, dynamic> json) {
    return Cat(
      id: json['id'] as String,
      name: json['name'] as String,
      breed: CatBreed.values[json['breed'] as int],
      adoptionDate: DateTime.parse(json['adoptionDate'] as String),
      experiencePoints: json['experiencePoints'] as int,
      growthStage: CatGrowthStage.values[json['growthStage'] as int],
      mood: CatMoodState.values[json['mood'] as int],
      energyLevel: json['energyLevel'] as int,
      affectionLevel: json['affectionLevel'] as int,
      unlockedAccessories: List<String>.from(json['unlockedAccessories']),
      equippedAccessories: Map<String, String>.from(json['equippedAccessories']),
    );
  }
  
  // 随机生成猫咪
  factory Cat.random() {
    final now = DateTime.now();
    final id = 'cat_${now.millisecondsSinceEpoch}';
    final randomBreed = CatBreed.values[DateTime.now().millisecond % CatBreed.values.length];
    
    return Cat(
      id: id,
      name: '未命名猫咪',
      breed: randomBreed,
      adoptionDate: now,
    );
  }
} 