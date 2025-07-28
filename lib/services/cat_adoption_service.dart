import 'dart:math';
import '../models/cat.dart';

/// 猫咪个性特征枚举
enum CatPersonality {
  playful, // 活泼好动
  calm, // 温和安静
  curious, // 好奇探索
  lazy, // 慵懒悠闲
  social, // 社交活跃
  independent // 独立自主
}

/// 猫咪认领服务类
class CatAdoptionService {
  static final Random _random = Random();

  /// 生成随机猫咪
  Future<Cat> generateRandomCat() async {
    // 随机选择品种（排除random）
    final breeds =
        CatBreed.values.where((breed) => breed != CatBreed.random).toList();
    final randomBreed = breeds[_random.nextInt(breeds.length)];

    // 生成随机个性
    final personality =
        CatPersonality.values[_random.nextInt(CatPersonality.values.length)];

    // 根据个性调整初始属性
    final attributes = _generatePersonalityBasedAttributes(personality);

    return Cat(
      name: '', // 名字将在用户输入后设置
      breed: randomBreed,
      energyLevel: attributes['energy']!,
      happiness: attributes['happiness']!,
      playSkill: attributes['playSkill']!,
      trainingSkill: attributes['trainingSkill']!,
    );
  }

  /// 根据品种生成猫咪名字建议
  Future<List<String>> suggestNames(CatBreed breed) async {
    final Map<CatBreed, List<String>> breedNames = {
      CatBreed.persian: [
        '雪球',
        '棉花',
        '公主',
        '贵妃',
        '丝丝',
        '绒绒',
        '珍珠',
        '月亮',
        '白雪',
        '云朵',
        '天使',
        '小仙',
        '糖糖',
        '奶昔',
        '布丁',
        '蛋糕'
      ],
      CatBreed.ragdoll: [
        '布布',
        '娃娃',
        '软软',
        '抱抱',
        '甜心',
        '蜜糖',
        '小乖',
        '宝贝',
        '温柔',
        '柔柔',
        '暖暖',
        '心心',
        '爱爱',
        '亲亲',
        '乖乖',
        '萌萌'
      ],
      CatBreed.siamese: [
        '咖啡',
        '摩卡',
        '拿铁',
        '焦糖',
        '巧克力',
        '可可',
        '奶茶',
        '布朗',
        '小棕',
        '栗子',
        '核桃',
        '杏仁',
        '花生',
        '芝麻',
        '肉桂',
        '香草'
      ],
      CatBreed.bengal: [
        '小虎',
        '斑斑',
        '花花',
        '豹豹',
        '金金',
        '橙橙',
        '阳光',
        '火火',
        '琥珀',
        '黄金',
        '柠檬',
        '橘子',
        '芒果',
        '南瓜',
        '胡萝卜',
        '玉米'
      ],
      CatBreed.maineCoon: [
        '大王',
        '威威',
        '强强',
        '巨巨',
        '熊熊',
        '狮子',
        '国王',
        '将军',
        '勇士',
        '英雄',
        '巨人',
        '泰山',
        '雷神',
        '战神',
        '霸王',
        '统帅'
      ],
    };

    // 通用可爱名字
    final commonNames = [
      '小咪',
      '喵喵',
      '咪咪',
      '小猫',
      '猫猫',
      '喵星人',
      '小可爱',
      '宝宝',
      '小乖',
      '甜甜',
      '蜜蜜',
      '糖糖',
      '果果',
      '朵朵',
      '花花',
      '美美',
      '乐乐',
      '欢欢',
      '笑笑',
      '开心',
      '快乐',
      '幸福',
      '甜心',
      '宝贝'
    ];

    final suggestions = <String>[];

    // 添加品种特定名字
    if (breedNames.containsKey(breed)) {
      final breedSpecific = breedNames[breed]!;
      suggestions.addAll(breedSpecific.take(8));
    }

    // 添加通用名字
    final shuffledCommon = List<String>.from(commonNames)..shuffle(_random);
    suggestions.addAll(shuffledCommon.take(8));

    // 打乱并返回前12个
    suggestions.shuffle(_random);
    return suggestions.take(12).toList();
  }

  /// 验证猫咪名字
  bool validateCatName(String name) {
    final trimmedName = name.trim();

    // 检查长度
    if (trimmedName.isEmpty || trimmedName.length > 10) {
      return false;
    }

    // 检查是否包含特殊字符（允许中文、英文、数字和常见符号）
    final validPattern = RegExp(r'^[\u4e00-\u9fa5a-zA-Z0-9\s\-_♥♡★☆]+$');
    if (!validPattern.hasMatch(trimmedName)) {
      return false;
    }

    // 检查是否为纯空格或特殊字符
    if (trimmedName.replaceAll(RegExp(r'[\s\-_♥♡★☆]'), '').isEmpty) {
      return false;
    }

    return true;
  }

  /// 获取名字验证错误信息
  String getNameValidationError(String name) {
    final trimmedName = name.trim();

    if (trimmedName.isEmpty) {
      return '请给你的猫咪取个名字吧~';
    }

    if (trimmedName.length > 10) {
      return '名字太长了，请控制在10个字符以内';
    }

    final validPattern = RegExp(r'^[\u4e00-\u9fa5a-zA-Z0-9\s\-_♥♡★☆]+$');
    if (!validPattern.hasMatch(trimmedName)) {
      return '名字包含不支持的字符，请使用中文、英文、数字或常见符号';
    }

    if (trimmedName.replaceAll(RegExp(r'[\s\-_♥♡★☆]'), '').isEmpty) {
      return '名字不能只包含空格或符号';
    }

    return '';
  }

  /// 根据个性生成属性
  Map<String, int> _generatePersonalityBasedAttributes(
      CatPersonality personality) {
    final baseEnergy = 80 + _random.nextInt(21); // 80-100
    final baseHappiness = 40 + _random.nextInt(21); // 40-60

    switch (personality) {
      case CatPersonality.playful:
        return {
          'energy': (baseEnergy * 1.1).clamp(0, 100).toInt(),
          'happiness': (baseHappiness * 1.2).clamp(0, 100).toInt(),
          'playSkill': 2 + _random.nextInt(2), // 2-3
          'trainingSkill': 1 + _random.nextInt(2), // 1-2
        };
      case CatPersonality.calm:
        return {
          'energy': (baseEnergy * 0.9).clamp(0, 100).toInt(),
          'happiness': (baseHappiness * 1.1).clamp(0, 100).toInt(),
          'playSkill': 1,
          'trainingSkill': 2 + _random.nextInt(2), // 2-3
        };
      case CatPersonality.curious:
        return {
          'energy': baseEnergy,
          'happiness': (baseHappiness * 1.15).clamp(0, 100).toInt(),
          'playSkill': 1 + _random.nextInt(2), // 1-2
          'trainingSkill': 2 + _random.nextInt(2), // 2-3
        };
      case CatPersonality.lazy:
        return {
          'energy': (baseEnergy * 0.8).clamp(0, 100).toInt(),
          'happiness': baseHappiness,
          'playSkill': 1,
          'trainingSkill': 1,
        };
      case CatPersonality.social:
        return {
          'energy': baseEnergy,
          'happiness': (baseHappiness * 1.3).clamp(0, 100).toInt(),
          'playSkill': 2 + _random.nextInt(2), // 2-3
          'trainingSkill': 1 + _random.nextInt(2), // 1-2
        };
      case CatPersonality.independent:
        return {
          'energy': (baseEnergy * 1.05).clamp(0, 100).toInt(),
          'happiness': (baseHappiness * 0.9).clamp(0, 100).toInt(),
          'playSkill': 1 + _random.nextInt(2), // 1-2
          'trainingSkill': 2 + _random.nextInt(2), // 2-3
        };
    }
  }

  /// 获取个性描述
  String getPersonalityDescription(CatPersonality personality) {
    switch (personality) {
      case CatPersonality.playful:
        return '活泼好动，喜欢玩耍和运动，精力充沛';
      case CatPersonality.calm:
        return '温和安静，性格平稳，容易训练';
      case CatPersonality.curious:
        return '好奇心强，喜欢探索新事物，学习能力强';
      case CatPersonality.lazy:
        return '慵懒悠闲，喜欢安静休息，节奏缓慢';
      case CatPersonality.social:
        return '社交活跃，喜欢与人互动，情感丰富';
      case CatPersonality.independent:
        return '独立自主，有自己的想法，适应能力强';
    }
  }

  /// 获取个性图标
  String getPersonalityIcon(CatPersonality personality) {
    switch (personality) {
      case CatPersonality.playful:
        return '⚡';
      case CatPersonality.calm:
        return '🌸';
      case CatPersonality.curious:
        return '🔍';
      case CatPersonality.lazy:
        return '😴';
      case CatPersonality.social:
        return '💕';
      case CatPersonality.independent:
        return '👑';
    }
  }
}
