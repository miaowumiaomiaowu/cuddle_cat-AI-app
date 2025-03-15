import 'dart:convert';
import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/cat.dart';
import '../models/dialogue.dart';

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
      if (_apiKey == null || _apiEndpoint == null) {
        debugPrint('API密钥或端点未配置，请检查.env文件');
        debugPrint('apiKey: ${_apiKey?.substring(0, 5)}..., endpoint: $_apiEndpoint');
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
      
      // 构建请求体 - 修正为DeepSeek API格式
      final Map<String, dynamic> requestBody = {
        "model": "deepseek-chat",  // DeepSeek通用对话模型
        "messages": messages,
        "temperature": 0.8,
        "max_tokens": 600,
        "stream": false,
      };
      
      debugPrint('正在发送API请求到: $_apiEndpoint');
      final jsonBody = jsonEncode(requestBody);
      debugPrint('请求体: ${jsonBody.substring(0, min(100, jsonBody.length))}...');
      
      // 设置超时
      final client = http.Client();
      try {
        // 发送请求
        final response = await client.post(
          Uri.parse(_apiEndpoint),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_apiKey',
          },
          body: jsonBody,
        ).timeout(const Duration(seconds: 15), onTimeout: () {
          throw TimeoutException('API请求超时');
        });
        
        // 解析响应
        debugPrint('收到API响应，状态码: ${response.statusCode}');
        if (response.statusCode == 200) {
          debugPrint('API响应成功，解析回复内容');
          final responseData = jsonDecode(response.body);
          debugPrint('响应数据: ${response.body.substring(0, min(100, response.body.length))}...');
          
          try {
            final String replyContent = responseData['choices'][0]['message']['content'];
            debugPrint('猫咪回复: ${replyContent.substring(0, min(50, replyContent.length))}...');
            
            // 分析回复的情感
            final emotionType = _analyzeReplyEmotion(replyContent, cat);
            
            // 创建猫咪回复消息
            return DialogueMessage.fromCat(
              text: replyContent,
              emotionType: emotionType,
            );
          } catch (e) {
            debugPrint('解析API响应时出错: $e');
            throw Exception('解析API响应时出错: $e');
          }
        } else {
          debugPrint('API请求失败: ${response.statusCode}');
          debugPrint('错误响应体: ${response.body}');
          
          // 如果API请求失败，返回一个默认回复
          return DialogueMessage.fromCat(
            text: '喵？似乎我有点累了，能稍后再和我聊聊吗？(API错误: ${response.statusCode})',
            emotionType: EmotionType.confused,
          );
        }
      } finally {
        client.close();
      }
    } catch (e) {
      debugPrint('生成猫咪回复时出错: $e');
      
      // 发生异常时，返回一个安全的默认回复
      return DialogueMessage.fromCat(
        text: '喵呜...好像有什么地方不太对劲。${cat.name}需要休息一下。(错误: $e)',
        emotionType: EmotionType.confused,
      );
    }
  }
  
  /// 构建系统提示词
  String _buildSystemPrompt(Cat cat) {
    final String breedPersonality = _getBreedPersonality(cat.breed);
    final String moodTrait = _getMoodPersonality(cat.mood);
    final String breedName = _getBreedName(cat.breed);
    
    return '''
你是一只名叫${cat.name}的虚拟宠物猫，品种是${breedName}。

个性特点：
- ${breedPersonality}
- 当前情绪状态：${moodTrait}
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
  
  /// 分析回复的情感类型
  EmotionType _analyzeReplyEmotion(String reply, Cat cat) {
    reply = reply.toLowerCase();
    
    // 开心情绪关键词
    if (reply.contains('开心') || 
        reply.contains('高兴') || 
        reply.contains('喜欢') ||
        reply.contains('兴奋') ||
        reply.contains('喵喵喵') ||
        reply.contains('~') ||
        reply.contains('!') ||
        reply.contains('！')) {
      return EmotionType.happy;
    }
    
    // 爱的情绪关键词
    if (reply.contains('爱') || 
        reply.contains('蹭') ||
        reply.contains('温暖') ||
        reply.contains('舔') ||
        reply.contains('呼噜')) {
      return EmotionType.loving;
    }
    
    // 悲伤情绪关键词
    if (reply.contains('难过') || 
        reply.contains('伤心') || 
        reply.contains('不开心')) {
      return EmotionType.sad;
    }
    
    // 困惑情绪关键词
    if (reply.contains('不明白') || 
        reply.contains('不懂') || 
        reply.contains('奇怪') ||
        reply.contains('困惑')) {
      return EmotionType.confused;
    }
    
    // 惊讶情绪关键词
    if (reply.contains('惊讶') || 
        reply.contains('吃惊') || 
        reply.contains('不敢相信') ||
        reply.contains('哇')) {
      return EmotionType.surprised;
    }
    
    // 默认根据猫咪当前心情返回相应情绪
    if (cat.mood == CatMoodState.happy) {
      return EmotionType.happy;
    } else if (cat.mood == CatMoodState.hungry || cat.mood == CatMoodState.tired) {
      return EmotionType.neutral;
    } else {
      return EmotionType.neutral;
    }
  }
} 