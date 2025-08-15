import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/dialogue.dart';
import '../models/cat.dart';
import 'ai_service.dart';

/// 对话服务类
class DialogueService {
  static const String _dialogueSessionKey = 'dialogue_sessions';

  // 当前活跃会话
  DialogueSession? _activeSession;

  // 历史会话列表
  final List<DialogueSession> _historySessions = [];

  // AI服务实例
  final AIService _aiService = AIService();

  /// 获取当前活跃会话
  DialogueSession? get activeSession => _activeSession;

  /// 获取历史会话列表
  List<DialogueSession> get historySessions => _historySessions;

  /// AI模式状态
  bool useAI = true;

  /// 加载会话历史
  Future<void> loadSessions() async {
    final prefs = await SharedPreferences.getInstance();

    try {
      final sessionsJson = prefs.getStringList(_dialogueSessionKey) ?? [];
      _historySessions.clear();

      for (var sessionStr in sessionsJson) {
        final sessionMap = jsonDecode(sessionStr);
        _historySessions.add(DialogueSession.fromJson(sessionMap));
      }

      _historySessions
          .sort((a, b) => b.lastUpdateTime.compareTo(a.lastUpdateTime));

      // 设置最近的会话为活跃会话
      if (_historySessions.isNotEmpty) {
        _activeSession = _historySessions.first;
      }
    } catch (e) {
      debugPrint('加载对话会话失败: $e');
    }
  }

  /// 保存会话历史
  Future<void> saveSessions() async {
    final prefs = await SharedPreferences.getInstance();

    try {
      final sessionJsonList = _historySessions
          .map((session) => jsonEncode(session.toJson()))
          .toList();

      await prefs.setStringList(_dialogueSessionKey, sessionJsonList);
    } catch (e) {
      debugPrint('保存对话会话失败: $e');
    }
  }

  /// 创建新会话
  DialogueSession createNewSession() {
    final session = DialogueSession.create();
    _activeSession = session;
    _historySessions.insert(0, session);
    saveSessions();
    return session;
  }

  /// 添加用户消息并生成猫咪回复
  Future<DialogueMessage> processUserMessage({
    required String messageText,
    required Cat cat,
  }) async {
    // 确保有活跃会话
    if (_activeSession == null) {
      createNewSession();
    }

    // 创建用户消息
    final userMessage = DialogueMessage.fromUser(
      text: messageText,
      emotionType: _analyzeUserEmotion(messageText),
    );

    // 添加到会话
    _activeSession!.addMessage(userMessage);

    // 生成猫咪回复
    DialogueMessage catReply;

    // 统一使用 AI 生成；失败则抛出异常，由上层展示“无网络/服务异常”
    try {
      debugPrint('尝试使用AI服务生成回复...');
      catReply = await _aiService.generateCatReply(
        userMessage: userMessage,
        cat: cat,
        conversationHistory: _activeSession!.messages,
      );
      debugPrint('AI回复生成成功: ${catReply.text.substring(0, min(30, catReply.text.length))}...');
    } catch (e) {
      debugPrint('AI生成回复失败: $e');
      rethrow;
    }

    // 添加猫咪回复到会话
    _activeSession!.addMessage(catReply);

    // 保存会话
    await saveSessions();

    return catReply;
  }

  /// 分析用户消息情感
  EmotionType _analyzeUserEmotion(String message) {
    // 这里是简单的情感分析，实际应用中可以接入更复杂的NLP服务

    message = message.toLowerCase();

    // 开心情绪关键词
    final happyKeywords = [
      '开心',
      '高兴',
      '快乐',
      '兴奋',
      '棒',
      '好',
      '喜欢',
      '爱',
      '笑',
      '哈哈',
      '嘻嘻',
      '耶',
      '哇',
      '太好了',
      '好棒',
      '开心',
      '好玩',
      '哈',
      '嘿',
      '玩',
      'happy',
      'joy',
      'excited',
      'good',
      'great'
    ];

    // 悲伤情绪关键词
    final sadKeywords = [
      '难过',
      '伤心',
      '痛苦',
      '悲伤',
      '哭',
      '泪',
      '失望',
      '叹气',
      '唉',
      '哎',
      '呜',
      '唔',
      '哭泣',
      '痛苦',
      '遗憾',
      '心痛',
      'sad',
      'upset',
      'depressed',
      'unhappy',
      'cry',
      'tears'
    ];

    // 生气情绪关键词
    final angryKeywords = [
      '生气',
      '愤怒',
      '气愤',
      '讨厌',
      '恨',
      '恼怒',
      '烦',
      '不爽',
      '可恶',
      '讨厌',
      '恨死了',
      '混蛋',
      '滚',
      '笨',
      '烦人',
      'angry',
      'mad',
      'hate',
      'annoyed',
      'irritated'
    ];

    // 焦虑情绪关键词
    final anxiousKeywords = [
      '担心',
      '焦虑',
      '紧张',
      '害怕',
      '怕',
      '恐惧',
      '担忧',
      '不安',
      '烦恼',
      '忧虑',
      '慌',
      '急',
      '没底',
      '困难',
      'anxious',
      'worried',
      'nervous',
      'afraid',
      'scared'
    ];

    // 困惑情绪关键词
    final confusedKeywords = [
      '困惑',
      '疑惑',
      '不明白',
      '不懂',
      '不理解',
      '迷茫',
      '奇怪',
      '怎么',
      '为什么',
      '啊',
      '嗯',
      '呃',
      '什么意思',
      '怎么回事',
      'confused',
      'puzzled',
      'wonder',
      'strange',
      'why'
    ];

    // 惊讶情绪关键词
    final surprisedKeywords = [
      '惊讶',
      '震惊',
      '吃惊',
      '不敢相信',
      '天啊',
      '天哪',
      '哇',
      '啊',
      '真的吗',
      '不会吧',
      '不可能',
      '竟然',
      '太神奇了',
      'surprised',
      'amazed',
      'wow',
      'incredible'
    ];

    // 关爱情绪关键词
    final lovingKeywords = [
      '关心',
      '爱护',
      '照顾',
      '疼爱',
      '喜欢你',
      '爱你',
      '感谢',
      '谢谢',
      '亲爱',
      '好喜欢',
      '很暖',
      '温暖',
      '温柔',
      '体贴',
      'love',
      'care',
      'thank',
      'appreciate',
      'grateful'
    ];

    // 匹配情感关键词
    if (happyKeywords.any((word) => message.contains(word))) {
      return EmotionType.happy;
    } else if (sadKeywords.any((word) => message.contains(word))) {
      return EmotionType.sad;
    } else if (angryKeywords.any((word) => message.contains(word))) {
      return EmotionType.angry;
    } else if (anxiousKeywords.any((word) => message.contains(word))) {
      return EmotionType.anxious;
    } else if (confusedKeywords.any((word) => message.contains(word))) {
      return EmotionType.confused;
    } else if (surprisedKeywords.any((word) => message.contains(word))) {
      return EmotionType.surprised;
    } else if (lovingKeywords.any((word) => message.contains(word))) {
      return EmotionType.loving;
    }

    return EmotionType.neutral;
  }

  // 移除模板聊天逻辑，统一由 AIService 生成



}
