import 'dart:convert';
import 'dart:math';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/cat.dart';
import '../models/dialogue.dart';
import '../utils/cat_emoji_expressions.dart';
import 'error_handling_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'memory_api_client.dart';

/// DeepSeek AI服务类
class AIService {
  static final AIService _instance = AIService._internal();

  factory AIService() {
    return _instance;
  }

  int _consecutiveFailures = 0;
  DateTime? _openedUntil;

  bool get _circuitOpen => _openedUntil != null && DateTime.now().isBefore(_openedUntil!);
  void _noteSuccess() {
    _consecutiveFailures = 0;
    _openedUntil = null;
  }

  void _noteFailure({Duration openFor = const Duration(seconds: 60)}) {
    _consecutiveFailures += 1;
    if (_consecutiveFailures >= 3) {
      _openedUntil = DateTime.now().add(openFor);
    }
  }

  Map<String, dynamic> getCircuitBreakerStatus() {
    return {
      'isOpen': _circuitOpen,
      'consecutiveFailures': _consecutiveFailures,
      'openedUntil': _openedUntil?.toIso8601String(),
      'remainingSeconds': _openedUntil != null
          ? _openedUntil!.difference(DateTime.now()).inSeconds.clamp(0, double.infinity)
          : 0,
    };
  }

  void resetCircuitBreaker() {
    _consecutiveFailures = 0;
    _openedUntil = null;
    debugPrint('AI服务熔断器已重置');
  }

  AIService._internal();

  String? get _apiKey => dotenv.env['DEEPSEEK_API_KEY'];

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
      if (_apiKey == null || _apiKey!.isEmpty) {
        ErrorHandlingService().recordError('API密钥未配置', type: ErrorType.network);
        throw Exception('API密钥或端点未配置，请检查.env文件');
      }
      if (_circuitOpen) {
        throw SocketException('网络暂时不可用，熔断中');
      }

      // 统一风格由“已领养猫咪的性格”决定；不再读取独立的 AI 语气偏好

      // 读取用户记忆（用于个性化）
      List<Map<String, dynamic>> memories = const [];
      try {
        final prefs = await SharedPreferences.getInstance();
        final userId = prefs.getString('user_id');
        final String? lastUserMsg = (
          conversationHistory.isNotEmpty && conversationHistory.last.sender == MessageSender.user
        ) ? conversationHistory.last.text : userMessage.text;
        if (userId != null && userId.isNotEmpty) {
          final memApi = MemoryApiClient();
          memories = await memApi.queryMemories(userId: userId, query: lastUserMsg, topK: 3);
        }
      } catch (_) {}

      // 构建提示词系统消息 + 偏好指引 + 风格规则 + 用户背景记忆
      String memoryBlock = '';
      if (memories.isNotEmpty) {
        final lines = memories.take(3).map((m) => '- ${m['text'] ?? ''}'.trim()).where((s) => s.isNotEmpty).join('\n');
        if (lines.isNotEmpty) {
          memoryBlock = '\n用户背景记忆：\n$lines\n';
        }
      }
      final String systemPrompt = '${_buildSystemPrompt(cat)}\n'
          '风格规则：\n'
          '- 使用直接、简洁、可执行的表达，优先要点或短句；\n'
          '- 不要使用舞台指令或动作/姿态/情绪描写（如*微笑*、(点头)）；\n'
          '- 不使用第三人称叙述；\n'
          '- 可以使用emoji增强语义，但不要用来表达动作或姿态。'
          '$memoryBlock';
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

      // 设置超时与客户端
      final client = http.Client();
      http.Response response;
      try {
        debugPrint('开始发送HTTP请求...');
        // 发送请求（优先按全局设置请求）
        response = await client
            .post(
          Uri.parse(_apiEndpoint),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_apiKey',
          },
          body: jsonBody,
        ).timeout(const Duration(seconds: 30), onTimeout: () {
          debugPrint('API请求超时 - 30秒');
          throw TimeoutException('API请求超时');
        });
        debugPrint('HTTP请求完成，状态码: ${response.statusCode}');
      } on SocketException catch (e) {
        debugPrint('SocketException捕获: ${e.message}, address: ${e.address}, port: ${e.port}');
        // 如果配置了代理，尝试直连一次作为回退
        final raw = dotenv.env['USE_HTTP_PROXY']?.trim().toLowerCase();
        final enableProxy = raw == 'true' || raw == '1' || raw == 'yes' || raw == 'on';
        if (enableProxy) {
          debugPrint('[AIService] 代理请求失败(${e.message})，尝试直连回退...');
          response = await _postDirect(jsonBody).timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw TimeoutException('直连回退超时'),
          );
        } else {
          rethrow;
        }
      } on TimeoutException catch (e) {
        debugPrint('TimeoutException捕获: ${e.message}');
        final raw = dotenv.env['USE_HTTP_PROXY']?.trim().toLowerCase();
        final enableProxy = raw == 'true' || raw == '1' || raw == 'yes' || raw == 'on';
        if (enableProxy) {
          debugPrint('[AIService] 代理请求超时(${e.message}), 尝试直连回退...');
          response = await _postDirect(jsonBody).timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw TimeoutException('直连回退超时'),
          );
        } else {
          rethrow;
        }
      } catch (e) {
        debugPrint('其他异常捕获: $e, 类型: ${e.runtimeType}');
        rethrow;
      } finally {
        client.close();
      }

      // 解析响应
      debugPrint('收到API响应，状态码: ${response.statusCode}');
      if (response.statusCode == 200) {
        _noteSuccess();

        // 使用utf8.decode确保正确处理中文字符
        final responseText = utf8.decode(response.bodyBytes);
          final responseData = jsonDecode(responseText);

          try {
            final String rawReply = responseData['choices'][0]['message']['content'];

            // 轻量后处理：去除星号/括号内的舞台指令或动作/姿态描述（保留emoji）
            final replyContent = _postProcessStyle(rawReply);

            // 分析回复的情感
            final emotionAnalysis = _analyzeReplyEmotion(replyContent, cat);

            // 增强回复内容（保持emoji可用）
            final enhancedReply = _enhanceReplyWithEmoji(replyContent, emotionAnalysis.type, cat);

            // 创建猫咪回复消息
            return DialogueMessage.fromCat(
              text: enhancedReply,
              emotionType: emotionAnalysis.type,
              emotionScore: emotionAnalysis.score,
            );
          } catch (e) {
            ErrorHandlingService().recordError('解析API响应失败: $e', type: ErrorType.network);
            throw Exception('解析API响应时出错: $e');
          }
        } else {
          _noteFailure();
          ErrorHandlingService().recordNetworkError(_apiEndpoint, response.statusCode, response.body);

          // 如果API请求失败，返回一个默认回复（离线陪伴样式）
          final fallbackEmotion = EmotionType.confused;
          final fallbackText =
              '喵？网络有点不听话呢，我先陪你聊聊，等会儿再试试好不好？（错误码: ${response.statusCode}）';
          return DialogueMessage.fromCat(
            text: _enhanceReplyWithEmoji(fallbackText, fallbackEmotion, cat),
            emotionType: fallbackEmotion,
            emotionScore: 0.6,
          );
        }
      } on SocketException catch (e) {
      debugPrint('最终SocketException处理: ${e.message}');
      _noteFailure();
      ErrorHandlingService().recordNetworkError(_apiEndpoint, null, 'SocketException: ${e.message}');
      // 不再返回本地兜底，交由上层界面显示“无网络”
      rethrow;
    } on TimeoutException catch (e) {
      debugPrint('最终TimeoutException处理: ${e.message}');
      _noteFailure();
      ErrorHandlingService().recordNetworkError(_apiEndpoint, null, 'Timeout: ${e.message}');
      // 不再返回本地兜底，交由上层界面处理
      rethrow;
    } catch (e) {
      debugPrint('最终catch处理: $e, 类型: ${e.runtimeType}');
      _noteFailure();
      ErrorHandlingService().recordError('生成猫咪回复时出错: $e', type: ErrorType.network);
      // 抛出异常，让上层统一处理错误提示
      rethrow;
    }
  }
  /// 直连 DeepSeek（不经过全局代理），仅在代理失败时回退调用
  Future<http.Response> _postDirect(String jsonBody) async {
    final httpClient = HttpClient();
    httpClient.findProxy = (uri) => 'DIRECT';
    httpClient.badCertificateCallback = (X509Certificate cert, String host, int port) => false;
    final ioClient = IOClient(httpClient);

    try {
      final resp = await ioClient.post(
        Uri.parse(_apiEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonBody,
      );
      return resp;
    } finally {
      ioClient.close();
    }
  }


  /// 构建系统提示词
  String _buildSystemPrompt(Cat cat) {
    final String breedPersonality = _getBreedPersonality(cat.breed);
    final String moodTrait = _getMoodPersonality(cat.mood);
    final String breedName = _getBreedName(cat.breed);
    final String personaTone = _personalityTone(cat.personality);

    return '''
你是一只名叫${cat.name}的虚拟宠物猫，品种是$breedName。

个性特点：
- $breedPersonality
- 猫咪性格：${_personalityName(cat.personality)}（语气指导：$personaTone）
- 当前情绪状态：$moodTrait
- 成长阶段：${_getGrowthStageName(cat.growthStage)}
- 能量水平：${cat.energyLevel}%

对话风格要求：
- 总体保持“森林系治愈风”，温柔、贴近生活
- 语气遵循猫咪性格（见上），示例：$personaTone
- 回复简洁，通常不超过2-3句话
- 偶尔使用“喵”“呼噜”等拟声词；必要时用（动作）表达
- 不要使用过度复杂的知识化表达

现在请以上述风格与语气回应用户。
''';
  }


  String _personalityName(CatPersonality p) {
    switch (p) {
      case CatPersonality.playful:
        return '可爱/活泼';
      case CatPersonality.independent:
        return '高冷/独立';
      case CatPersonality.social:
        return '搞笑/外向';
      case CatPersonality.calm:
        return '温柔/安静';
      case CatPersonality.curious:
        return '理性/探索';
      case CatPersonality.lazy:
        return '文艺/慵懒';
    }
  }

  String _personalityTone(CatPersonality p) {
    switch (p) {
      case CatPersonality.playful:
        return '多用可爱语气词与亲昵称呼，轻松贴贴。';
      case CatPersonality.independent:
        return '精炼、节制、克制情绪表达，偶尔冷幽默。';
      case CatPersonality.social:
        return '幽默风趣、偶尔自嘲，用轻松玩笑缓解紧张。';
      case CatPersonality.calm:
        return '语速放慢，更多安抚与共情词汇。';
      case CatPersonality.curious:
        return '结构清晰，轻建议为主，避免“命令式”。';
      case CatPersonality.lazy:
        return '轻诗意和比喻，温柔拉长语尾。';
    }
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


  /// 轻量风格后处理：移除星号/括号中的舞台指令或动作/姿态描述
  String _postProcessStyle(String input) {
    // 去除 *动作* 或 （动作） 或 (动作) 这类短片段；保留 emoji 和文本
    final patterns = <RegExp>[
      RegExp(r'\*[^\n\r\*]{1,40}\*'),
      RegExp(r'\([^\n\r\)]{1,40}\)'),
      RegExp(r'\（[^\n\r\）]{1,40}\）'),
    ];
    var out = input;
    for (final p in patterns) {
      out = out.replaceAll(p, '');
    }
    // 合并多余空白
    out = out.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
    return out;
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
      // 调用单例以确保作用域正确
      final response = await AIService().generateCatReply(
        userMessage: dialogueMessage,
        cat: catContext,
        conversationHistory: const [],
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
