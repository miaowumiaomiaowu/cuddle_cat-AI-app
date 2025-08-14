import 'memory_service.dart';

class BreakthroughDetector {
  final MemoryService _memoryService = MemoryService();
  
  // 突破关键词映射
  static const Map<String, List<String>> _breakthroughKeywords = {
    '社交突破': ['第一次', '主动', '交流', '聊天', '朋友', '社交', '说话'],
    '恐惧克服': ['不再害怕', '克服', '勇敢', '尝试', '挑战', '突破'],
    '习惯养成': ['坚持', '连续', '天', '习惯', '每天', '规律'],
    '情绪管理': ['平静', '冷静', '控制', '情绪', '不再焦虑', '放松'],
    '自我接纳': ['接受', '原谅', '自己', '不完美', '理解'],
    '创作表达': ['创作', '写', '画', '表达', '分享', '作品'],
  };

  Future<void> analyzeConversation(String message) async {
    final lowerMessage = message.toLowerCase();
    
    for (final entry in _breakthroughKeywords.entries) {
      final category = entry.key;
      final keywords = entry.value;
      
      // 检查是否包含突破关键词
      final matchedKeywords = keywords.where((keyword) => 
        lowerMessage.contains(keyword)).toList();
      
      if (matchedKeywords.length >= 2) {
        // 检测到潜在突破
        await _detectBreakthrough(
          category: category,
          context: message,
          keywords: matchedKeywords,
        );
      }
    }
    
    // 特殊模式检测
    await _detectSpecialPatterns(message);
  }

  Future<void> _detectBreakthrough({
    required String category,
    required String context,
    required List<String> keywords,
  }) async {
    // 生成突破总结
    String summary = _generateBreakthroughSummary(category, context);
    
    await _memoryService.detectAndSaveBreakthrough(
      context: context,
      keywords: [category, ...keywords],
      summary: summary,
    );
  }

  Future<void> _detectSpecialPatterns(String message) async {
    final lower = message.toLowerCase();
    
    // 检测"第一次"模式
    if (lower.contains('第一次') && (
        lower.contains('做') || 
        lower.contains('尝试') || 
        lower.contains('去'))) {
      await _memoryService.detectAndSaveBreakthrough(
        context: message,
        keywords: ['第一次', '尝试', '突破'],
        summary: '勇敢尝试了新的事物',
      );
    }
    
    // 检测"不再"模式
    if (lower.contains('不再') && (
        lower.contains('害怕') || 
        lower.contains('担心') || 
        lower.contains('焦虑'))) {
      await _memoryService.detectAndSaveBreakthrough(
        context: message,
        keywords: ['克服', '恐惧', '成长'],
        summary: '成功克服了内心的恐惧',
      );
    }
    
    // 检测连续行为模式
    final consecutivePattern = RegExp(r'连续|坚持.{0,10}(\d+).{0,5}天');
    final match = consecutivePattern.firstMatch(lower);
    if (match != null) {
      await _memoryService.detectAndSaveBreakthrough(
        context: message,
        keywords: ['坚持', '习惯', '毅力'],
        summary: '培养了良好的习惯并坚持下来',
      );
    }
  }

  String _generateBreakthroughSummary(String category, String context) {
    switch (category) {
      case '社交突破':
        return '在社交方面有了新的突破';
      case '恐惧克服':
        return '勇敢地克服了内心的恐惧';
      case '习惯养成':
        return '成功培养了新的好习惯';
      case '情绪管理':
        return '在情绪管理上取得了进步';
      case '自我接纳':
        return '学会了更好地接纳自己';
      case '创作表达':
        return '在创作表达上有了新的尝试';
      default:
        return '取得了值得庆祝的进步';
    }
  }

  Future<void> analyzeTaskCompletion({
    required String taskTitle,
    required int consecutiveDays,
    required String category,
  }) async {
    if (consecutiveDays >= 7) {
      await _memoryService.detectAndSaveBreakthrough(
        context: '连续${consecutiveDays}天完成「$taskTitle」',
        keywords: ['坚持', '习惯', category],
        summary: '坚持完成「$taskTitle」，培养了良好习惯',
      );
    }
  }

  Future<void> analyzeMoodImprovement({
    required List<String> recentMoods,
    required int improvementDays,
  }) async {
    if (improvementDays >= 3) {
      await _memoryService.detectAndSaveBreakthrough(
        context: '心情连续${improvementDays}天保持积极',
        keywords: ['情绪', '改善', '积极'],
        summary: '心情状态持续改善，情绪管理能力提升',
      );
    }
  }
}
