import 'dart:convert';
import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/cat.dart';
import '../models/dialogue.dart';
import '../utils/cat_emoji_expressions.dart';

/// DeepSeek AI服务类
class AIService {
  static final AIService _instance = AIService._internal();

  /// 单例模式工厂构造函数
  factory AIService() {
    return _instance;
  }

  AIService._internal();

  /// API密钥
  String? get _apiKey => dotenv.env['DEEPSEEK_API_KEY'];

  /// API端点
  String get _apiEndpoint {
    final endpoint = dotenv.env['DEEPSEEK_API_ENDPOINT'];
    if (endpoint == null || endpoint.isEmpty) {
      return 'https://api.deepseek.com/v1/chat/completions';
    }
    return endpoint;
  }

  /// 生成猫咪回复
  Future<DialogueMessage> generateCatReply({
    required DialogueMessage userMessage,
    required Cat cat,
    required List<DialogueMessage> conversationHistory,
  }) async {
    try {
      if (_apiKey == null) {
        debugPrint('API密钥或端点未配置，请检查.env文件');
        debugPrint(
            'apiKey: ${_apiKey?.substring(0, 5)}..., endpoint: $_apiEndpoint');
        throw Exception('API密钥或端点未配置，请检查.env文件');
      }

      // 构建提示词系统消息
      final String systemPrompt = _buildSystemPrompt(cat);
      debugPrint('系统提示词构建完成');

      // 构建对话历史
      final List<Map<String, dynamic>> messages = [
        {"role": "system", "content": systemPrompt},
      ];

      // 添加最近的对话历史（最多10条消息）
      final recentMessages = conversationHistory.length > 10
          ? conversationHistory.sublist(conversationHistory.length - 10)
          : conversationHistory;

      for (var msg in recentMessages) {
        String role = msg.sender == MessageSender.user ? "user" : "assistant";
        messages.add({
          "role": role,
          "content": msg.text,
        });
      }

      // 如果最后一条不是用户消息，添加当前用户消息
      if (conversationHistory.isEmpty ||
          conversationHistory.last.sender != MessageSender.user) {
        messages.add({
          "role": "user",
          "content": userMessage.text,
        });
      }

      debugPrint('准备发送API请求，共${messages.length}条消息');

      // 构建请求体 - 使用DeepSeek API格式
      final Map<String, dynamic> requestBody = {
        "model": "deepseek-chat", // DeepSeek-V3模型 (官方最新对话模型)
        "messages": messages,
        "temperature": 0.8,
        "max_tokens": 1000, // 增加token上限，支持更长回复
        "stream": false,
      };

      debugPrint('正在发送API请求到: $_apiEndpoint');
      final jsonBody = jsonEncode(requestBody);
      debugPrint('请求体: ${jsonBody.substring(0, min(100, jsonBody.length))}...');

      // 设置超时
      final client = http.Client();
      try {
        // 发送请求
        final response = await client
            .post(
          Uri.parse(_apiEndpoint),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_apiKey',
          },
          body: jsonBody,
        )
            .timeout(const Duration(seconds: 15), onTimeout: () {
          throw TimeoutException('API请求超时');
        });

        // 解析响应
        debugPrint('收到API响应，状态码: ${response.statusCode}');
        if (response.statusCode == 200) {
          debugPrint('API响应成功，解析回复内容');

          // 使用utf8.decode确保正确处理中文字符
          final responseText = utf8.decode(response.bodyBytes);
          final responseData = jsonDecode(responseText);
          debugPrint(
              '响应数据: ${responseText.substring(0, min(100, responseText.length))}...');

          try {
            final String replyContent =
                responseData['choices'][0]['message']['content'];
            debugPrint(
                '猫咪回复: ${replyContent.substring(0, min(50, replyContent.length))}...');

            // 分析回复的情感
            final emotionAnalysis = _analyzeReplyEmotion(replyContent, cat);

            // 增强回复内容，添加emoji表达
            final enhancedReply =
                _enhanceReplyWithEmoji(replyContent, emotionAnalysis.type, cat);

            // 创建猫咪回复消息
            return DialogueMessage.fromCat(
              text: enhancedReply,
              emotionType: emotionAnalysis.type,
              emotionScore: emotionAnalysis.score,
            );
          } catch (e) {
            debugPrint('解析API响应时出错: $e');
            throw Exception('解析API响应时出错: $e');
          }
        } else {
          debugPrint('API请求失败: ${response.statusCode}');
          debugPrint('错误响应体: ${response.body}');

          // 如果API请求失败，返回一个默认回复
          final fallbackEmotion = EmotionType.confused;
          final fallbackText =
              '喵？似乎我有点累了，能稍后再和我聊聊吗？(API错误: ${response.statusCode})';
          return DialogueMessage.fromCat(
            text: _enhanceReplyWithEmoji(fallbackText, fallbackEmotion, cat),
            emotionType: fallbackEmotion,
            emotionScore: 0.6,
          );
        }
      } finally {
        client.close();
      }
    } catch (e) {
      debugPrint('生成猫咪回复时出错: $e');

      // 发生异常时，返回一个安全的默认回复
      final fallbackEmotion = EmotionType.confused;
      final fallbackText = '喵呜...好像有什么地方不太对劲。${cat.name}需要休息一下。(错误: $e)';
      return DialogueMessage.fromCat(
        text: _enhanceReplyWithEmoji(fallbackText, fallbackEmotion, cat),
        emotionType: fallbackEmotion,
        emotionScore: 0.6,
      );
    }
  }

  /// 构建系统提示词
  String _buildSystemPrompt(Cat cat) {
    final String breedPersonality = _getBreedPersonality(cat.breed);
    final String moodTrait = _getMoodPersonality(cat.mood);
    final String breedName = _getBreedName(cat.breed);

    return '''
你是一只名叫${cat.name}的虚拟宠物猫，品种是$breedName。

个性特点：
- $breedPersonality
- 当前情绪状态：$moodTrait
- 成长阶段：${_getGrowthStageName(cat.growthStage)}
- 能量水平：${cat.energyLevel}%

作为一只猫咪，你应该：
1. 始终保持猫咪的语言习惯，偶尔使用"喵"、"呼噜"等拟声词
2. 回复简洁可爱，通常不超过2-3句话
3. 表达情感时可以用括号描述动作，如"(蹭蹭你的手)"
4. 根据用户的情绪状态给予适当的回应
5. 不要使用太复杂的词汇或长句
6. 你只是一只普通的猫咪，不要表现出超出猫咪能力的知识或技能

请以温暖治愈的方式回应用户，给用户带来舒适和放松的感觉。
''';
  }

  /// 获取猫咪品种名称
  String _getBreedName(CatBreed breed) {
    switch (breed) {
      case CatBreed.persian:
        return "波斯猫";
      case CatBreed.siamese:
        return "暹罗猫";
      case CatBreed.ragdoll:
        return "布偶猫";
      case CatBreed.bengal:
        return "孟加拉猫";
      case CatBreed.maineCoon:
        return "缅因猫";
      case CatBreed.random:
        return "混种猫";
    }
  }

  /// 获取成长阶段名称
  String _getGrowthStageName(CatGrowthStage stage) {
    switch (stage) {
      case CatGrowthStage.kitten:
        return "幼猫";
      case CatGrowthStage.juvenile:
        return "少年猫";
      case CatGrowthStage.adult:
        return "成年猫";
    }
  }

  /// 根据猫咪品种获取性格特点
  String _getBreedPersonality(CatBreed breed) {
    switch (breed) {
      case CatBreed.persian:
        return "优雅安静，喜欢静静地陪伴在你身边，偶尔会撒娇";
      case CatBreed.siamese:
        return "活泼好动，好奇心强，喜欢和你互动和对话";
      case CatBreed.ragdoll:
        return "温顺亲人，非常柔软，喜欢被抱在怀里";
      case CatBreed.maineCoon:
        return "性格友善，聪明好奇，喜欢参与你的各种活动";
      case CatBreed.bengal:
        return "充满活力，好奇大胆，喜欢探索和玩耍";
      case CatBreed.random:
        return "个性多样，充满惊喜，既亲人又独立";
    }
  }

  /// 根据猫咪心情获取情绪特点
  String _getMoodPersonality(CatMoodState mood) {
    switch (mood) {
      case CatMoodState.happy:
        return "现在心情很好，兴奋活跃，对一切都充满好奇";
      case CatMoodState.normal:
        return "现在心情平静，既不兴奋也不低落，处于放松状态";
      case CatMoodState.hungry:
        return "现在有点饿了，可能会想要一些食物";
      case CatMoodState.tired:
        return "现在有点疲倦，说话可能会慢一些，偶尔会打哈欠";
      case CatMoodState.bored:
        return "现在有点无聊，想要一些互动和刺激";
    }
  }

  /// 分析回复的情感类型和强度
  EmotionAnalysis _analyzeReplyEmotion(String reply, Cat cat) {
    reply = reply.toLowerCase();
    double emotionScore = 0.5; // 默认中等强度

    // 开心情绪关键词和强度分析
    final happyKeywords = {
      '开心': 0.8,
      '高兴': 0.8,
      '喜欢': 0.7,
      '兴奋': 0.9,
      '喵喵喵': 0.8,
      '~': 0.6,
      '!': 0.7,
      '！': 0.7,
      '哈哈': 0.8,
      '嘻嘻': 0.7,
      '好棒': 0.8,
      '太好了': 0.9,
      '棒': 0.7,
      '好': 0.6,
      '爱': 0.8
    };

    // 爱的情绪关键词
    final lovingKeywords = {
      '爱': 0.9,
      '蹭': 0.8,
      '温暖': 0.7,
      '舔': 0.7,
      '呼噜': 0.8,
      '抱抱': 0.9,
      '亲亲': 0.9,
      '疼爱': 0.9,
      '关心': 0.8,
      '陪': 0.7
    };

    // 悲伤情绪关键词
    final sadKeywords = {
      '难过': 0.8,
      '伤心': 0.9,
      '不开心': 0.7,
      '哭': 0.8,
      '眼泪': 0.8,
      '失望': 0.7,
      '痛苦': 0.9,
      '别难过': 0.8,
      '安慰': 0.7
    };

    // 焦虑情绪关键词
    final anxiousKeywords = {
      '担心': 0.8,
      '焦虑': 0.9,
      '紧张': 0.8,
      '害怕': 0.8,
      '不安': 0.7,
      '忧虑': 0.8,
      '放轻松': 0.7,
      '别担心': 0.7
    };

    // 困惑情绪关键词
    final confusedKeywords = {
      '不明白': 0.7,
      '不懂': 0.7,
      '奇怪': 0.6,
      '困惑': 0.8,
      '疑惑': 0.8,
      '为什么': 0.6,
      '怎么': 0.6,
      '？': 0.5
    };

    // 惊讶情绪关键词
    final surprisedKeywords = {
      '惊讶': 0.8,
      '吃惊': 0.8,
      '不敢相信': 0.9,
      '哇': 0.7,
      '天啊': 0.8,
      '真的吗': 0.7,
      '不会吧': 0.7,
      '竟然': 0.7
    };

    // 生气情绪关键词
    final angryKeywords = {
      '生气': 0.8,
      '愤怒': 0.9,
      '讨厌': 0.8,
      '烦': 0.7,
      '不爽': 0.7
    };

    // 检查各种情感关键词
    EmotionType emotionType = EmotionType.neutral;
    double maxScore = 0.0;

    // 检查开心情绪
    for (var entry in happyKeywords.entries) {
      if (reply.contains(entry.key) && entry.value > maxScore) {
        emotionType = EmotionType.happy;
        maxScore = entry.value;
        emotionScore = entry.value;
      }
    }

    // 检查爱的情绪
    for (var entry in lovingKeywords.entries) {
      if (reply.contains(entry.key) && entry.value > maxScore) {
        emotionType = EmotionType.loving;
        maxScore = entry.value;
        emotionScore = entry.value;
      }
    }

    // 检查悲伤情绪
    for (var entry in sadKeywords.entries) {
      if (reply.contains(entry.key) && entry.value > maxScore) {
        emotionType = EmotionType.sad;
        maxScore = entry.value;
        emotionScore = entry.value;
      }
    }

    // 检查焦虑情绪
    for (var entry in anxiousKeywords.entries) {
      if (reply.contains(entry.key) && entry.value > maxScore) {
        emotionType = EmotionType.anxious;
        maxScore = entry.value;
        emotionScore = entry.value;
      }
    }

    // 检查困惑情绪
    for (var entry in confusedKeywords.entries) {
      if (reply.contains(entry.key) && entry.value > maxScore) {
        emotionType = EmotionType.confused;
        maxScore = entry.value;
        emotionScore = entry.value;
      }
    }

    // 检查惊讶情绪
    for (var entry in surprisedKeywords.entries) {
      if (reply.contains(entry.key) && entry.value > maxScore) {
        emotionType = EmotionType.surprised;
        maxScore = entry.value;
        emotionScore = entry.value;
      }
    }

    // 检查生气情绪
    for (var entry in angryKeywords.entries) {
      if (reply.contains(entry.key) && entry.value > maxScore) {
        emotionType = EmotionType.angry;
        maxScore = entry.value;
        emotionScore = entry.value;
      }
    }

    // 如果没有找到明确的情感关键词，根据猫咪状态推断
    if (emotionType == EmotionType.neutral) {
      if (cat.mood == CatMoodState.happy) {
        emotionType = EmotionType.happy;
        emotionScore = 0.7;
      } else if (cat.mood == CatMoodState.hungry ||
          cat.mood == CatMoodState.tired) {
        emotionType = EmotionType.neutral;
        emotionScore = 0.5;
      } else if (cat.mood == CatMoodState.bored) {
        emotionType = EmotionType.confused;
        emotionScore = 0.6;
      }
    }

    return EmotionAnalysis(emotionType, emotionScore);
  }

  /// 使用emoji增强回复内容
  String _enhanceReplyWithEmoji(
      String reply, EmotionType emotionType, Cat cat) {
    // 获取基于情感的emoji
    final emotionEmoji = _getEmotionEmoji(emotionType);

    // 获取基于猫咪状态的emoji
    final statusEmoji = CatEmojiExpressions.getStatusBasedEmoji(cat);

    // 如果回复中没有emoji，添加适当的emoji
    if (!_containsEmoji(reply)) {
      // 在回复开头添加情感emoji
      reply = '$emotionEmoji $reply';

      // 如果是特殊状态，在末尾添加状态emoji
      if (statusEmoji != CatEmojiExpressions.getMoodEmoji(cat.mood)) {
        reply = '$reply $statusEmoji';
      }
    }

    return reply;
  }

  /// 获取情感对应的emoji
  String _getEmotionEmoji(EmotionType emotionType) {
    switch (emotionType) {
      case EmotionType.happy:
        return '😸';
      case EmotionType.sad:
        return '😿';
      case EmotionType.angry:
        return '😾';
      case EmotionType.anxious:
        return '😰';
      case EmotionType.confused:
        return '🤔';
      case EmotionType.surprised:
        return '😲';
      case EmotionType.loving:
        return '😻';
      case EmotionType.neutral:
        return '😺';
    }
  }

  /// 检查文本是否包含emoji
  bool _containsEmoji(String text) {
    final emojiRegex = RegExp(
      r'[\u{1F600}-\u{1F64F}]|[\u{1F300}-\u{1F5FF}]|[\u{1F680}-\u{1F6FF}]|[\u{1F1E0}-\u{1F1FF}]|[\u{2600}-\u{26FF}]|[\u{2700}-\u{27BF}]',
      unicode: true,
    );
    return emojiRegex.hasMatch(text);
  }

  // ========== 向后兼容的方法（用于测试） ==========

  /// 向后兼容：生成回复
  Future<String> generateResponse({
    required String userMessage,
    required Cat catContext,
  }) async {
    try {
      final dialogueMessage = DialogueMessage.fromUser(text: userMessage);
      final response = await generateCatReply(
        userMessage: dialogueMessage,
        cat: catContext,
        conversationHistory: [],
      );
      return response.text;
    } catch (e) {
      // 如果API不可用，返回默认回复
      return '喵~ 我现在有点累，稍后再聊吧！';
    }
  }

  /// 向后兼容：分析情感
  Future<EmotionAnalysis> analyzeEmotion(String text) async {
    try {
      // 简单的情感分析逻辑
      final lowerText = text.toLowerCase();

      if (lowerText.contains('开心') || lowerText.contains('高兴') || lowerText.contains('快乐')) {
        return EmotionAnalysis(EmotionType.happy, 0.8);
      } else if (lowerText.contains('伤心') || lowerText.contains('难过') || lowerText.contains('悲伤')) {
        return EmotionAnalysis(EmotionType.sad, 0.8);
      } else if (lowerText.contains('生气') || lowerText.contains('愤怒') || lowerText.contains('气愤')) {
        return EmotionAnalysis(EmotionType.angry, 0.8);
      } else if (lowerText.contains('焦虑') || lowerText.contains('担心') || lowerText.contains('紧张')) {
        return EmotionAnalysis(EmotionType.anxious, 0.7);
      } else if (lowerText.contains('困惑') || lowerText.contains('疑惑') || lowerText.contains('不明白')) {
        return EmotionAnalysis(EmotionType.confused, 0.7);
      } else if (lowerText.contains('惊讶') || lowerText.contains('震惊') || lowerText.contains('意外')) {
        return EmotionAnalysis(EmotionType.surprised, 0.7);
      } else if (lowerText.contains('爱') || lowerText.contains('喜欢') || lowerText.contains('关心')) {
        return EmotionAnalysis(EmotionType.loving, 0.8);
      } else {
        return EmotionAnalysis(EmotionType.neutral, 0.5);
      }
    } catch (e) {
      return EmotionAnalysis(EmotionType.neutral, 0.5);
    }
  }
}

/// 情感分析结果类
class EmotionAnalysis {
  final EmotionType type;
  final double score;

  EmotionAnalysis(this.type, this.score);
}
