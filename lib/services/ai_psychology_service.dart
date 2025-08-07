import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:math';
import '../models/mood_record.dart';
import '../models/user.dart';

/// AI心理支持服务 - 提供智能对话和情绪分析
class AIPsychologyService {
  static const String _apiKey = 'your_openai_api_key'; // 实际项目中应该从环境变量获取
  
  /// 分析心情记录并提供建议
  Future<PsychologyInsight> analyzeMoodPattern(List<MoodEntry> entries, User user) async {
    try {
      // 简化实现：基于规则的分析（实际项目中可以调用AI API）
      return _generateInsightFromPattern(entries, user);
    } catch (e) {
      debugPrint('AI心理分析失败: $e');
      return _getDefaultInsight();
    }
  }

  /// 生成个性化建议
  Future<List<String>> generatePersonalizedAdvice(MoodEntry currentMood, List<MoodEntry> recentEntries) async {
    try {
      return _generateAdviceBasedOnMood(currentMood, recentEntries);
    } catch (e) {
      debugPrint('生成个性化建议失败: $e');
      return _getDefaultAdvice();
    }
  }

  /// 情绪对话支持
  Future<String> getChatResponse(String userMessage, MoodType currentMood, List<MoodEntry> context) async {
    try {
      // 简化实现：基于规则的对话（实际项目中可以调用ChatGPT API）
      return _generateChatResponse(userMessage, currentMood, context);
    } catch (e) {
      debugPrint('AI对话失败: $e');
      return _getDefaultChatResponse(currentMood);
    }
  }

  /// 心理健康评估
  Future<MentalHealthAssessment> assessMentalHealth(List<MoodEntry> entries, User user) async {
    try {
      return _calculateMentalHealthScore(entries, user);
    } catch (e) {
      debugPrint('心理健康评估失败: $e');
      return _getDefaultAssessment();
    }
  }

  /// 冥想引导推荐
  Future<List<MeditationGuide>> recommendMeditation(MoodType currentMood, int intensity) async {
    try {
      return _getMeditationRecommendations(currentMood, intensity);
    } catch (e) {
      debugPrint('冥想推荐失败: $e');
      return _getDefaultMeditations();
    }
  }

  // 私有方法 - 基于规则的分析实现

  PsychologyInsight _generateInsightFromPattern(List<MoodEntry> entries, User user) {
    if (entries.isEmpty) return _getDefaultInsight();

    final recentEntries = entries.take(30).toList(); // 最近30条记录
    final positiveCount = recentEntries.where((e) => e.isPositive).length;
    final negativeCount = recentEntries.where((e) => e.isNegative).length;
    final averageIntensity = recentEntries.map((e) => e.intensity).reduce((a, b) => a + b) / recentEntries.length;

    String mainInsight;
    List<String> recommendations;
    double wellnessScore;

    if (positiveCount > negativeCount * 2) {
      mainInsight = '你最近的心情状态很棒！积极情绪占主导地位，这表明你正在经历一个相对愉快的时期。';
      recommendations = [
        '继续保持现在的生活方式和心态',
        '可以尝试记录让你开心的具体事情，以便将来参考',
        '考虑与朋友分享你的快乐，传播正能量',
      ];
      wellnessScore = 0.8 + (positiveCount / recentEntries.length) * 0.2;
    } else if (negativeCount > positiveCount * 1.5) {
      mainInsight = '最近你可能面临一些挑战，消极情绪比较多。这是正常的，每个人都会有低潮期。';
      recommendations = [
        '尝试每天记录三件感恩的事情',
        '增加户外活动和运动时间',
        '考虑与信任的朋友或专业人士交流',
        '保证充足的睡眠和健康的饮食',
      ];
      wellnessScore = 0.3 + (positiveCount / recentEntries.length) * 0.4;
    } else {
      mainInsight = '你的情绪状态比较平衡，有起有落是正常的生活状态。';
      recommendations = [
        '继续保持情绪记录的好习惯',
        '注意识别和处理压力源',
        '培养一些让你放松的兴趣爱好',
      ];
      wellnessScore = 0.5 + (averageIntensity / 10) * 0.3;
    }

    return PsychologyInsight(
      mainInsight: mainInsight,
      recommendations: recommendations,
      wellnessScore: wellnessScore.clamp(0.0, 1.0),
      analysisDate: DateTime.now(),
      dataPoints: recentEntries.length,
    );
  }

  List<String> _generateAdviceBasedOnMood(MoodEntry currentMood, List<MoodEntry> recentEntries) {
    switch (currentMood.mood) {
      case MoodType.anxious:
        return [
          '尝试深呼吸练习：4秒吸气，4秒屏息，4秒呼气',
          '将注意力集中在当下，观察周围的5样东西',
          '写下你担心的事情，然后问自己：这些担心有多现实？',
          '考虑进行轻度运动，如散步或瑜伽',
        ];
      case MoodType.sad:
        return [
          '允许自己感受这种情绪，哭泣是正常的释放方式',
          '联系一位信任的朋友或家人',
          '做一些你通常喜欢的活动，即使现在不太想做',
          '写下你的感受，有时表达出来会有帮助',
        ];
      case MoodType.angry:
        return [
          '在回应之前先暂停几秒钟',
          '进行一些体力活动来释放能量',
          '尝试理解愤怒背后的真实需求',
          '使用"我"语句表达感受，而不是指责他人',
        ];
      case MoodType.stressed:
        return [
          '列出你的任务，按优先级排序',
          '将大任务分解成小步骤',
          '安排一些放松时间，即使只有10分钟',
          '考虑哪些事情可以委托或推迟',
        ];
      case MoodType.lonely:
        return [
          '主动联系一位老朋友',
          '参加社区活动或兴趣小组',
          '考虑志愿服务，帮助他人也能让自己感觉更好',
          '记住孤独是暂时的感受，不是永久状态',
        ];
      default:
        return [
          '继续保持情绪记录的习惯',
          '注意观察什么活动让你感觉更好',
          '保持规律的作息和健康的生活方式',
          '记住寻求帮助是勇敢的表现',
        ];
    }
  }

  String _generateChatResponse(String userMessage, MoodType currentMood, List<MoodEntry> context) {
    final responses = _getChatResponseTemplates(currentMood);
    final random = Random();
    
    // 简化实现：基于关键词匹配
    final message = userMessage.toLowerCase();
    
    if (message.contains('难过') || message.contains('伤心')) {
      return responses['sad']![random.nextInt(responses['sad']!.length)];
    } else if (message.contains('焦虑') || message.contains('担心')) {
      return responses['anxious']![random.nextInt(responses['anxious']!.length)];
    } else if (message.contains('开心') || message.contains('高兴')) {
      return responses['happy']![random.nextInt(responses['happy']!.length)];
    } else if (message.contains('压力') || message.contains('累')) {
      return responses['stressed']![random.nextInt(responses['stressed']!.length)];
    } else {
      return responses['general']![random.nextInt(responses['general']!.length)];
    }
  }

  Map<String, List<String>> _getChatResponseTemplates(MoodType currentMood) {
    return {
      'sad': [
        '我理解你现在的感受。难过是一种正常的情绪，允许自己感受它。你想聊聊是什么让你感到难过吗？',
        '每个人都会有低落的时候，这不代表你有什么问题。你已经很勇敢地在记录和面对自己的情绪了。',
        '虽然现在感觉很难，但这种感受会过去的。你有什么通常能让自己感觉好一点的方法吗？',
      ],
      'anxious': [
        '焦虑让人很不舒服，我能感受到你的不安。让我们一起尝试一些放松的方法，好吗？',
        '当我们焦虑时，往往会想象最坏的情况。让我们回到现实，专注于你现在能控制的事情。',
        '深呼吸可能会有帮助。试试4-7-8呼吸法：吸气4秒，屏息7秒，呼气8秒。',
      ],
      'happy': [
        '看到你心情不错，我也很开心！能分享一下是什么让你感到快乐吗？',
        '积极的情绪很珍贵，记住这种感觉，它可以在困难时给你力量。',
        '你的好心情很有感染力！保持这种积极的能量。',
      ],
      'stressed': [
        '压力确实很难承受。让我们一起想想如何减轻一些负担，好吗？',
        '当压力很大时，记住你不需要一次解决所有问题。一步一步来。',
        '你已经在努力应对了，这本身就很了不起。给自己一些信用。',
      ],
      'general': [
        '谢谢你与我分享。我在这里倾听你的感受。',
        '每个人的情绪都是独特和有价值的。你的感受很重要。',
        '记录情绪是自我关爱的一种方式。你做得很好。',
        '我很高兴你愿意关注自己的心理健康。这是很重要的一步。',
      ],
    };
  }

  MentalHealthAssessment _calculateMentalHealthScore(List<MoodEntry> entries, User user) {
    if (entries.isEmpty) return _getDefaultAssessment();

    final recentEntries = entries.take(30).toList();
    final positiveRatio = recentEntries.where((e) => e.isPositive).length / recentEntries.length;
    final averageIntensity = recentEntries.map((e) => e.intensity).reduce((a, b) => a + b) / recentEntries.length;
    final consistencyScore = _calculateConsistencyScore(recentEntries);

    final overallScore = (positiveRatio * 0.4 + (averageIntensity / 10) * 0.3 + consistencyScore * 0.3) * 100;

    String riskLevel;
    List<String> recommendations;

    if (overallScore >= 80) {
      riskLevel = 'low';
      recommendations = ['继续保持良好的心理状态', '定期进行自我检查'];
    } else if (overallScore >= 60) {
      riskLevel = 'moderate';
      recommendations = ['注意压力管理', '增加积极活动', '保持社交联系'];
    } else {
      riskLevel = 'high';
      recommendations = ['考虑寻求专业帮助', '增加自我关爱活动', '建立支持网络'];
    }

    return MentalHealthAssessment(
      overallScore: overallScore,
      riskLevel: riskLevel,
      recommendations: recommendations,
      assessmentDate: DateTime.now(),
      dataQuality: recentEntries.length >= 14 ? 'good' : 'limited',
    );
  }

  double _calculateConsistencyScore(List<MoodEntry> entries) {
    if (entries.length < 7) return 0.5;

    // 计算情绪波动的一致性
    final intensities = entries.map((e) => e.intensity).toList();
    final mean = intensities.reduce((a, b) => a + b) / intensities.length;
    final variance = intensities.map((i) => (i - mean) * (i - mean)).reduce((a, b) => a + b) / intensities.length;
    
    // 波动越小，一致性越高
    return (1 / (1 + variance / 10)).clamp(0.0, 1.0);
  }

  List<MeditationGuide> _getMeditationRecommendations(MoodType currentMood, int intensity) {
    switch (currentMood) {
      case MoodType.anxious:
        return [
          MeditationGuide(
            title: '焦虑缓解冥想',
            duration: 10,
            description: '通过深呼吸和身体扫描来缓解焦虑感',
            type: 'breathing',
            audioUrl: null,
          ),
          MeditationGuide(
            title: '正念观察',
            duration: 15,
            description: '观察当下的感受，不做判断',
            type: 'mindfulness',
            audioUrl: null,
          ),
        ];
      case MoodType.stressed:
        return [
          MeditationGuide(
            title: '压力释放',
            duration: 12,
            description: '渐进式肌肉放松，释放身体紧张',
            type: 'relaxation',
            audioUrl: null,
          ),
        ];
      default:
        return [
          MeditationGuide(
            title: '日常正念',
            duration: 8,
            description: '简单的正念练习，适合任何心情',
            type: 'general',
            audioUrl: null,
          ),
        ];
    }
  }

  // 默认返回值方法
  PsychologyInsight _getDefaultInsight() {
    return PsychologyInsight(
      mainInsight: '继续记录你的心情，这有助于更好地了解自己。',
      recommendations: ['保持记录习惯', '注意自我关爱'],
      wellnessScore: 0.5,
      analysisDate: DateTime.now(),
      dataPoints: 0,
    );
  }

  List<String> _getDefaultAdvice() {
    return [
      '保持规律的作息时间',
      '进行适量的运动',
      '与朋友和家人保持联系',
      '寻找让你快乐的活动',
    ];
  }

  String _getDefaultChatResponse(MoodType currentMood) {
    return '我在这里倾听你的感受。每个人的情绪都很重要，你做得很好。';
  }

  MentalHealthAssessment _getDefaultAssessment() {
    return MentalHealthAssessment(
      overallScore: 50.0,
      riskLevel: 'moderate',
      recommendations: ['继续记录心情', '保持健康生活方式'],
      assessmentDate: DateTime.now(),
      dataQuality: 'limited',
    );
  }

  List<MeditationGuide> _getDefaultMeditations() {
    return [
      MeditationGuide(
        title: '基础冥想',
        duration: 5,
        description: '简单的呼吸冥想',
        type: 'breathing',
        audioUrl: null,
      ),
    ];
  }
}

/// 心理洞察结果
class PsychologyInsight {
  final String mainInsight;
  final List<String> recommendations;
  final double wellnessScore; // 0.0 - 1.0
  final DateTime analysisDate;
  final int dataPoints;

  PsychologyInsight({
    required this.mainInsight,
    required this.recommendations,
    required this.wellnessScore,
    required this.analysisDate,
    required this.dataPoints,
  });
}

/// 心理健康评估
class MentalHealthAssessment {
  final double overallScore; // 0-100
  final String riskLevel; // low, moderate, high
  final List<String> recommendations;
  final DateTime assessmentDate;
  final String dataQuality; // good, limited, poor

  MentalHealthAssessment({
    required this.overallScore,
    required this.riskLevel,
    required this.recommendations,
    required this.assessmentDate,
    required this.dataQuality,
  });
}

/// 冥想指导
class MeditationGuide {
  final String title;
  final int duration; // 分钟
  final String description;
  final String type; // breathing, mindfulness, relaxation, general
  final String? audioUrl;

  MeditationGuide({
    required this.title,
    required this.duration,
    required this.description,
    required this.type,
    this.audioUrl,
  });
}
