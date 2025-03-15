import 'package:flutter/material.dart';

/// 对话消息发送者类型
enum MessageSender {
  user,   // 用户发送
  cat     // 猫咪发送
}

/// 情感类型
enum EmotionType {
  happy,      // 开心
  sad,        // 悲伤
  angry,      // 生气
  anxious,    // 焦虑
  neutral,    // 中性
  confused,   // 困惑
  surprised,  // 惊讶
  loving      // 关爱
}

/// 对话消息类
class DialogueMessage {
  final String text;                // 消息文本
  final MessageSender sender;       // 发送者
  final DateTime timestamp;         // 发送时间
  final EmotionType emotionType;    // 情感类型
  final double emotionScore;        // 情感强度分数 (0.0-1.0)
  
  const DialogueMessage({
    required this.text,
    required this.sender,
    required this.timestamp,
    this.emotionType = EmotionType.neutral,
    this.emotionScore = 0.5,
  });
  
  /// 从JSON创建消息
  factory DialogueMessage.fromJson(Map<String, dynamic> json) {
    return DialogueMessage(
      text: json['text'],
      sender: _senderFromString(json['sender']),
      timestamp: DateTime.parse(json['timestamp']),
      emotionType: _emotionFromString(json['emotionType']),
      emotionScore: json['emotionScore'],
    );
  }
  
  /// 创建用户消息
  factory DialogueMessage.fromUser({
    required String text,
    EmotionType emotionType = EmotionType.neutral,
    double emotionScore = 0.5,
  }) {
    return DialogueMessage(
      text: text,
      sender: MessageSender.user,
      timestamp: DateTime.now(),
      emotionType: emotionType,
      emotionScore: emotionScore,
    );
  }
  
  /// 创建猫咪消息
  factory DialogueMessage.fromCat({
    required String text,
    EmotionType emotionType = EmotionType.neutral,
    double emotionScore = 0.5,
  }) {
    return DialogueMessage(
      text: text,
      sender: MessageSender.cat,
      timestamp: DateTime.now(),
      emotionType: emotionType,
      emotionScore: emotionScore,
    );
  }
  
  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'sender': sender.toString().split('.').last,
      'timestamp': timestamp.toIso8601String(),
      'emotionType': emotionType.toString().split('.').last,
      'emotionScore': emotionScore,
    };
  }
  
  /// 从字符串转换为发送者枚举
  static MessageSender _senderFromString(String senderStr) {
    return MessageSender.values.firstWhere(
      (e) => e.toString().split('.').last == senderStr,
      orElse: () => MessageSender.user,
    );
  }
  
  /// 从字符串转换为情感枚举
  static EmotionType _emotionFromString(String emotionStr) {
    return EmotionType.values.firstWhere(
      (e) => e.toString().split('.').last == emotionStr,
      orElse: () => EmotionType.neutral,
    );
  }
  
  /// 获取情感颜色
  Color get emotionColor {
    switch (emotionType) {
      case EmotionType.happy:
        return Colors.yellow;
      case EmotionType.sad:
        return Colors.blue.shade300;
      case EmotionType.angry:
        return Colors.red;
      case EmotionType.anxious:
        return Colors.orange;
      case EmotionType.neutral:
        return Colors.grey;
      case EmotionType.confused:
        return Colors.purple.shade300;
      case EmotionType.surprised:
        return Colors.pink.shade300;
      case EmotionType.loving:
        return Colors.pink;
    }
  }
}

/// 对话会话类
class DialogueSession {
  final String id;                      // 会话ID
  final DateTime startTime;             // 开始时间
  DateTime lastUpdateTime;              // 最后更新时间
  final List<DialogueMessage> messages; // 消息列表
  
  DialogueSession({
    required this.id,
    required this.startTime,
    required this.lastUpdateTime,
    required this.messages,
  });
  
  /// 创建新会话
  factory DialogueSession.create() {
    final now = DateTime.now();
    return DialogueSession(
      id: 'session_${now.millisecondsSinceEpoch}',
      startTime: now,
      lastUpdateTime: now,
      messages: [
        DialogueMessage.fromCat(
          text: '喵~ 你好啊！今天想聊些什么呢？',
          emotionType: EmotionType.happy,
        ),
      ],
    );
  }
  
  /// 从JSON创建会话
  factory DialogueSession.fromJson(Map<String, dynamic> json) {
    return DialogueSession(
      id: json['id'],
      startTime: DateTime.parse(json['startTime']),
      lastUpdateTime: DateTime.parse(json['lastUpdateTime']),
      messages: (json['messages'] as List)
          .map((m) => DialogueMessage.fromJson(m))
          .toList(),
    );
  }
  
  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startTime': startTime.toIso8601String(),
      'lastUpdateTime': lastUpdateTime.toIso8601String(),
      'messages': messages.map((m) => m.toJson()).toList(),
    };
  }
  
  /// 添加一条消息
  void addMessage(DialogueMessage message) {
    messages.add(message);
    lastUpdateTime = DateTime.now();
  }
  
  /// 获取最新消息
  DialogueMessage? get lastMessage => 
      messages.isNotEmpty ? messages.last : null;
      
  /// 获取会话持续时间（分钟）
  int get durationInMinutes =>
      lastUpdateTime.difference(startTime).inMinutes;
} 