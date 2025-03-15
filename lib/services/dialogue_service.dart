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
  
  // AI模式开关
  bool _useAI = true;
  
  /// 获取当前活跃会话
  DialogueSession? get activeSession => _activeSession;
  
  /// 获取历史会话列表
  List<DialogueSession> get historySessions => _historySessions;
  
  /// 获取AI模式状态
  bool get useAI => _useAI;
  
  /// 设置AI模式状态
  set useAI(bool value) {
    _useAI = value;
  }
  
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
      
      _historySessions.sort((a, b) => b.lastUpdateTime.compareTo(a.lastUpdateTime));
      
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
      final sessionJsonList = _historySessions.map((session) => 
          jsonEncode(session.toJson())).toList();
      
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
    
    // 根据设置选择使用AI生成还是模板生成
    debugPrint('AI模式状态: ${_useAI ? "已开启" : "已关闭"}');
    if (_useAI) {
      try {
        debugPrint('尝试使用AI服务生成回复...');
        // 使用AI服务生成回复
        catReply = await _aiService.generateCatReply(
          userMessage: userMessage,
          cat: cat,
          conversationHistory: _activeSession!.messages,
        );
        debugPrint('AI回复生成成功: ${catReply.text.substring(0, min(30, catReply.text.length))}...');
      } catch (e) {
        debugPrint('AI生成回复失败: $e');
        // 如果AI生成失败，回退到模板生成
        debugPrint('回退到模板回复生成...');
        catReply = await _generateTemplateReply(
          userMessage: userMessage,
          cat: cat,
        );
      }
    } else {
      // 使用模板生成回复
      debugPrint('使用模板生成回复...');
      catReply = await _generateTemplateReply(
        userMessage: userMessage,
        cat: cat,
      );
    }
    
    // 添加猫咪回复到会话
    _activeSession!.addMessage(catReply);
    
    // 保存会话
    await saveSessions();
    
    return catReply;
  }
  
  /// 使用模板生成猫咪回复（作为备用方案）
  Future<DialogueMessage> _generateTemplateReply({
    required DialogueMessage userMessage,
    required Cat cat,
  }) async {
    // 根据用户情感和猫咪状态生成回复
    
    // 根据猫咪的心情和用户的情感类型选择不同的回复方式
    String reply = '';
    EmotionType catEmotion;
    
    // 获取合适的回复模板
    switch (userMessage.emotionType) {
      case EmotionType.happy:
        reply = _getHappyReply(cat);
        catEmotion = cat.mood == CatMoodState.happy 
            ? EmotionType.happy 
            : EmotionType.neutral;
        break;
      case EmotionType.sad:
        reply = _getSadReply(cat);
        catEmotion = EmotionType.loving;
        break;
      case EmotionType.angry:
        reply = _getAngryReply(cat);
        catEmotion = cat.mood == CatMoodState.happy 
            ? EmotionType.loving 
            : EmotionType.neutral;
        break;
      case EmotionType.anxious:
        reply = _getAnxiousReply(cat);
        catEmotion = EmotionType.loving;
        break;
      case EmotionType.confused:
        reply = _getConfusedReply(cat);
        catEmotion = EmotionType.neutral;
        break;
      case EmotionType.surprised:
        reply = _getSurprisedReply(cat);
        catEmotion = EmotionType.surprised;
        break;
      case EmotionType.loving:
        reply = _getLovingReply(cat);
        catEmotion = EmotionType.loving;
        break;
      case EmotionType.neutral:
      default:
        reply = _getNeutralReply(cat);
        catEmotion = cat.mood == CatMoodState.happy 
            ? EmotionType.happy 
            : EmotionType.neutral;
        break;
    }
    
    // 创建猫咪回复消息
    return DialogueMessage.fromCat(
      text: reply,
      emotionType: catEmotion,
    );
  }
  
  /// 分析用户消息情感
  EmotionType _analyzeUserEmotion(String message) {
    // 这里是简单的情感分析，实际应用中可以接入更复杂的NLP服务
    
    message = message.toLowerCase();
    
    // 开心情绪关键词
    final happyKeywords = [
      '开心', '高兴', '快乐', '兴奋', '棒', '好', '喜欢', '爱', '笑', 
      '哈哈', '嘻嘻', '耶', '哇', '太好了', '好棒', '开心', '好玩',
      '哈', '嘿', '玩', 'happy', 'joy', 'excited', 'good', 'great'
    ];
    
    // 悲伤情绪关键词
    final sadKeywords = [
      '难过', '伤心', '痛苦', '悲伤', '哭', '泪', '失望', '叹气', '唉', 
      '哎', '呜', '唔', '哭泣', '痛苦', '遗憾', '心痛',
      'sad', 'upset', 'depressed', 'unhappy', 'cry', 'tears'
    ];
    
    // 生气情绪关键词
    final angryKeywords = [
      '生气', '愤怒', '气愤', '讨厌', '恨', '恼怒', '烦', '不爽', '可恶', 
      '讨厌', '恨死了', '混蛋', '滚', '笨', '烦人',
      'angry', 'mad', 'hate', 'annoyed', 'irritated'
    ];
    
    // 焦虑情绪关键词
    final anxiousKeywords = [
      '担心', '焦虑', '紧张', '害怕', '怕', '恐惧', '担忧', '不安', 
      '烦恼', '忧虑', '慌', '急', '没底', '困难',
      'anxious', 'worried', 'nervous', 'afraid', 'scared'
    ];
    
    // 困惑情绪关键词
    final confusedKeywords = [
      '困惑', '疑惑', '不明白', '不懂', '不理解', '迷茫', '奇怪', '怎么', 
      '为什么', '啊', '嗯', '呃', '什么意思', '怎么回事',
      'confused', 'puzzled', 'wonder', 'strange', 'why'
    ];
    
    // 惊讶情绪关键词
    final surprisedKeywords = [
      '惊讶', '震惊', '吃惊', '不敢相信', '天啊', '天哪', '哇', '啊', 
      '真的吗', '不会吧', '不可能', '竟然', '太神奇了',
      'surprised', 'amazed', 'wow', 'incredible'
    ];
    
    // 关爱情绪关键词
    final lovingKeywords = [
      '关心', '爱护', '照顾', '疼爱', '喜欢你', '爱你', '感谢', '谢谢', 
      '亲爱', '好喜欢', '很暖', '温暖', '温柔', '体贴',
      'love', 'care', 'thank', 'appreciate', 'grateful'
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
  
  /// 获取开心回复
  String _getHappyReply(Cat cat) {
    final replies = [
      '喵~ 看到你这么开心，我也很开心呢！要一起玩游戏吗？',
      '喵喵！你的笑容真暖人心！我最喜欢看到你笑了~',
      '喵呜~ 开心的日子就是要一起分享才更快乐！',
      '呼噜呼噜~（${cat.name}蹭蹭你）我也觉得今天特别棒！',
      '喵喵喵！（${cat.name}兴奋地转圈）我们一起开心吧！',
      '喵~！好心情应该要庆祝一下，要不要摸摸我的头？',
    ];
    
    return _getRandomReply(replies);
  }
  
  /// 获取悲伤回复
  String _getSadReply(Cat cat) {
    final replies = [
      '喵... 别难过了，${cat.name}在这里陪着你呢。（轻轻蹭你）',
      '喵？怎么了，不开心吗？要不要抱抱${cat.name}？',
      '喵呜~（${cat.name}轻轻靠在你身边）我会一直陪着你的。',
      '喵..（${cat.name}担心地看着你）不管发生什么，都会好起来的。',
      '喵喵？（${cat.name}用头轻轻顶你的手）别担心，有我在呢。',
      '喵呜~心情不好的时候，抚摸猫咪会让你感觉好些哦。',
    ];
    
    return _getRandomReply(replies);
  }
  
  /// 获取生气回复
  String _getAngryReply(Cat cat) {
    final replies = [
      '喵？（${cat.name}警觉地看着你）发生什么事了？深呼吸，慢慢说。',
      '喵..别生气了，生气对身体不好。摸摸${cat.name}的毛，会平静下来的。',
      '喵呜？（${cat.name}小心地靠近）无论发生什么，我都站在你这边。',
      '喵喵..（${cat.name}安静地坐在你旁边）等你平静下来，我们再聊好吗？',
      '喵？生气的时候，不如和${cat.name}玩一会儿，心情会好很多的。',
      '喵呜..（${cat.name}轻轻舔你的手）别担心，一切都会好起来的。',
    ];
    
    return _getRandomReply(replies);
  }
  
  /// 获取焦虑回复
  String _getAnxiousReply(Cat cat) {
    final replies = [
      '喵~（${cat.name}靠在你身边）放轻松，一切都会好起来的。',
      '喵呜？有什么在困扰你吗？${cat.name}会一直陪着你的。',
      '喵..（${cat.name}蹭蹭你的手）深呼吸，慢慢来，我在这里。',
      '喵？别担心太多，现在抚摸我，会让你感觉好些的。',
      '喵喵~（${cat.name}温柔地看着你）无论遇到什么困难，我们一起面对。',
      '喵呜..焦虑的时候，摸摸猫咪的毛，听听呼噜声，会感觉安心很多。',
    ];
    
    return _getRandomReply(replies);
  }
  
  /// 获取困惑回复
  String _getConfusedReply(Cat cat) {
    final replies = [
      '喵？（${cat.name}歪头看着你）我虽然不太懂，但我会认真听你说。',
      '喵呜？（${cat.name}好奇地望着你）有什么疑问吗？也许我能帮上忙。',
      '喵..（${cat.name}眨眨眼）虽然我只是一只猫，但可以陪你一起想办法。',
      '喵？困惑的时候，不妨休息一下，和${cat.name}玩一会儿，也许答案就出现了。',
      '喵喵？有时候，答案不在思考中，而在放松时突然出现。不如先摸摸我？',
      '喵呜~（${cat.name}用爪子轻轻拍你）别想太多了，休息一下再思考吧。',
    ];
    
    return _getRandomReply(replies);
  }
  
  /// 获取惊讶回复
  String _getSurprisedReply(Cat cat) {
    final replies = [
      '喵！（${cat.name}竖起耳朵）发生了什么惊人的事情吗？',
      '喵呜？！（${cat.name}警觉地看着你）怎么了？是好事还是坏事？',
      '喵？！（${cat.name}跳到你身边）看你这么惊讶，是有什么大新闻吗？',
      '喵喵！（${cat.name}好奇地围着你转）快告诉我发生了什么！',
      '喵！惊讶的事情总是令人难忘，不过别忘了喵星人也很好奇呢！',
      '喵呜！（${cat.name}瞪大眼睛）我也很想知道发生了什么！',
    ];
    
    return _getRandomReply(replies);
  }
  
  /// 获取关爱回复
  String _getLovingReply(Cat cat) {
    final replies = [
      '喵~（${cat.name}幸福地蹭你）我也很爱你，你是我最好的朋友！',
      '呼噜呼噜~（${cat.name}满足地闭上眼睛）有你在身边真幸福。',
      '喵喵~（${cat.name}用头顶你的手）我永远都会陪在你身边的。',
      '喵呜~（${cat.name}舔你的手指）你对我这么好，我好开心！',
      '喵~（${cat.name}蜷缩在你腿上）和你在一起的每一刻都很珍贵。',
      '呼噜呼噜~你的关心是${cat.name}最大的幸福，我会一直爱你！',
    ];
    
    return _getRandomReply(replies);
  }
  
  /// 获取中性回复
  String _getNeutralReply(Cat cat) {
    final replies = [
      '喵~（${cat.name}好奇地看着你）今天过得怎么样？',
      '喵？有什么想和${cat.name}分享的吗？我很乐意听你说话。',
      '喵喵~（${cat.name}轻轻摇摆尾巴）今天的天气不错，适合小憩一会儿。',
      '喵呜~（${cat.name}伸了个懒腰）有时候放空一下思绪也很不错。',
      '喵？（${cat.name}眨眨眼）要不要摸摸我的毛？会让你心情变好哦。',
      '喵~（${cat.name}安静地坐在你旁边）无论你想做什么，我都陪着你。',
    ];
    
    return _getRandomReply(replies);
  }
  
  /// 随机获取一条回复
  String _getRandomReply(List<String> replies) {
    final random = Random();
    return replies[random.nextInt(replies.length)];
  }
} 