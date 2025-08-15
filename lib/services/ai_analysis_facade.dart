import '../models/happiness_task.dart';

class UserSignals {
  final List<String> recentMessages; // 最近对话文本（脱敏）
  final List<Map<String, dynamic>> moodRecords; // timestamp + mood + description
  final Map<String, dynamic> stats; // streak, completionRate
  final Map<String, dynamic>? weather; // 可选天气信息
  UserSignals({required this.recentMessages, required this.moodRecords, required this.stats, this.weather});
  UserSignals copyWith({List<String>? recentMessages, List<Map<String, dynamic>>? moodRecords, Map<String, dynamic>? stats, Map<String, dynamic>? weather}) =>
      UserSignals(recentMessages: recentMessages ?? this.recentMessages, moodRecords: moodRecords ?? this.moodRecords, stats: stats ?? this.stats, weather: weather ?? this.weather);
}

class GiftingTask {
  final String title;
  final String emoji;
  final String category;
  final String description;
  final String? reason; // 新增：生成原因/鼓励
  final int? estimatedMinutes;
  GiftingTask({required this.title, required this.emoji, required this.category, required this.description, this.reason, this.estimatedMinutes});
  HappinessTask toHappinessTask() => HappinessTask(
    title: title,
    emoji: emoji,
    category: category,
    description: description,
    reason: reason,
    estimatedMinutes: estimatedMinutes,
    frequency: 'once',
  );
}

class AnalysisResult {
  final List<String> emotions;
  final Map<String, double> scores;
  final List<GiftingTask> gifts;
  AnalysisResult({required this.emotions, required this.scores, required this.gifts});
}

abstract class AIAnalysisFacade {
  Future<AnalysisResult> analyzeAndRecommend(UserSignals input);
}

class AIAnalysisStub implements AIAnalysisFacade {
  @override
  Future<AnalysisResult> analyzeAndRecommend(UserSignals input) async {
    // 简单兜底：返回几条友好礼物
    final gifts = <GiftingTask>[
      GiftingTask(title: '去楼下散步', emoji: '🚶‍♀️', category: '运动', description: '轻松走10分钟，看看天空', estimatedMinutes: 10),
      GiftingTask(title: '给自己冲一杯热饮', emoji: '☕', category: '放松', description: '慢慢喝，感受温度', estimatedMinutes: 5),
      GiftingTask(title: '深呼吸小练习', emoji: '🌬️', category: '呼吸', description: '2-4-6-4节奏×3组', estimatedMinutes: 4),
    ];
    return AnalysisResult(emotions: const ['calm'], scores: const {'calm': 0.7}, gifts: gifts);
  }
}

