import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/cat_provider.dart';
import '../providers/mood_provider.dart';
import '../services/ai_psychology_service.dart';
import '../models/mood_record.dart';
import '../theme/artistic_theme.dart';
import '../widgets/floating_cat_assistant.dart';
import '../widgets/immersive_chat_widget.dart';
import '../widgets/function_bubble_menu.dart';
import '../widgets/quick_mood_record_sheet.dart';

/// 沉浸式聊天首页 - 创新设计
class ImmersiveChatHomeScreen extends StatefulWidget {
  const ImmersiveChatHomeScreen({super.key});

  @override
  State<ImmersiveChatHomeScreen> createState() => _ImmersiveChatHomeScreenState();
}

class _ImmersiveChatHomeScreenState extends State<ImmersiveChatHomeScreen>
    with TickerProviderStateMixin {
  
  // 聊天相关
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  
  // 悬浮猫咪相关
  bool _showFunctionMenu = false;
  late AnimationController _catAnimationController;
  late AnimationController _menuAnimationController;
  late Animation<double> _catPulseAnimation;
  late Animation<double> _menuScaleAnimation;
  
  // 背景动画
  late AnimationController _backgroundController;
  late Animation<Color?> _backgroundColorAnimation;
  
  // 服务
  final AIPsychologyService _aiService = AIPsychologyService();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadWelcomeMessage();
  }

  void _initializeAnimations() {
    // 猫咪脉冲动画
    _catAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _catPulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _catAnimationController,
      curve: Curves.easeInOut,
    ));
    _catAnimationController.repeat(reverse: true);

    // 菜单缩放动画
    _menuAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _menuScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _menuAnimationController,
      curve: Curves.elasticOut,
    ));

    // 背景颜色动画
    _backgroundController = AnimationController(
      duration: const Duration(minutes: 5),
      vsync: this,
    );
    _backgroundColorAnimation = ColorTween(
      begin: ArtisticTheme.backgroundColor,
      end: ArtisticTheme.primaryColor.withValues(alpha: 0.1),
    ).animate(_backgroundController);
    _backgroundController.repeat(reverse: true);
  }

  void _loadWelcomeMessage() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final catProvider = Provider.of<CatProvider>(context, listen: false);
      final cat = catProvider.cat;
      
      if (cat != null) {
        setState(() {
          _messages.add(ChatMessage(
            text: '喵~ 我是${cat.name}！今天想聊什么呢？我可以陪你聊天、记录心情，或者分享旅行故事哦~ 🐱✨',
            isUser: false,
            timestamp: DateTime.now(),
            avatar: '🐱',
            messageType: ChatMessageType.welcome,
          ));
        });
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _catAnimationController.dispose();
    _menuAnimationController.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _backgroundColorAnimation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _backgroundColorAnimation.value ?? ArtisticTheme.backgroundColor,
                  ArtisticTheme.backgroundColor,
                  ArtisticTheme.surfaceColor,
                ],
              ),
            ),
            child: SafeArea(
              child: Stack(
                children: [
                  // 主聊天界面
                  _buildChatInterface(),
                  
                  // 悬浮猫咪助手
                  _buildFloatingCatAssistant(),
                  
                  // 功能菜单
                  if (_showFunctionMenu) _buildFunctionMenu(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildChatInterface() {
    return Column(
      children: [
        // 顶部标题栏
        _buildTopBar(),
        
        // 聊天消息列表
        Expanded(
          child: ImmersiveChatWidget(
            messages: _messages,
            scrollController: _scrollController,
            isTyping: _isTyping,
          ),
        ),
        
        // 输入区域
        _buildInputArea(),
      ],
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          // 应用图标
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: ArtisticTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.pets,
              color: ArtisticTheme.primaryColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          
          // 标题
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '暖猫 AI 助手',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: ArtisticTheme.textPrimary,
                  ),
                ),
                Consumer<CatProvider>(
                  builder: (context, catProvider, child) {
                    final cat = catProvider.cat;
                    return Text(
                      cat != null ? '${cat.name} 在线陪伴' : '正在连接...',
                      style: ArtisticTheme.bodyStyle.copyWith(
                        fontSize: 12,
                        color: ArtisticTheme.textSecondary,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          
          // 状态指示器
          _buildStatusIndicator(),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator() {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.3),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ArtisticTheme.surfaceColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 心情记录快捷按钮
          GestureDetector(
            onTap: _showQuickMoodRecord,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.pink.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.pink.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.mood,
                color: Colors.pink,
                size: 24,
              ),
            ),
          ),

          const SizedBox(width: 12),

          // 输入框
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: ArtisticTheme.primaryColor.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: '和我聊聊吧...',
                  hintStyle: ArtisticTheme.bodyStyle.copyWith(
                    color: ArtisticTheme.textSecondary,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // 发送按钮
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: ArtisticTheme.primaryColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: ArtisticTheme.elevatedShadow,
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingCatAssistant() {
    return Positioned(
      right: 20,
      bottom: 100,
      child: FloatingCatAssistant(
        animation: _catPulseAnimation,
        onTap: _toggleFunctionMenu,
        showNotification: _messages.length <= 1, // 新用户显示提示
      ),
    );
  }

  Widget _buildFunctionMenu() {
    return Positioned(
      right: 20,
      bottom: 160,
      child: ScaleTransition(
        scale: _menuScaleAnimation,
        child: FunctionBubbleMenu(
          onMoodRecord: _openMoodRecord,
          onTravelRecord: _openTravelRecord,
          onSettings: _openSettings,
          onClose: _toggleFunctionMenu,
        ),
      ),
    );
  }

  void _toggleFunctionMenu() {
    setState(() {
      _showFunctionMenu = !_showFunctionMenu;
    });
    
    if (_showFunctionMenu) {
      _menuAnimationController.forward();
    } else {
      _menuAnimationController.reverse();
    }
    
    // 触觉反馈
    HapticFeedback.lightImpact();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isTyping) return;

    // 添加用户消息
    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
        avatar: '😊',
      ));
      _isTyping = true;
    });

    _messageController.clear();
    _scrollToBottom();

    try {
      // 智能判断消息类型并选择合适的回复方式
      final messageType = _analyzeMessageType(text);
      String response;
      ChatMessageType responseType;

      final moodProvider = Provider.of<MoodProvider>(context, listen: false);
      final catProvider = Provider.of<CatProvider>(context, listen: false);

      switch (messageType) {
        case UserMessageType.psychology:
          // 心理支持回复
          final currentMood = moodProvider.moodEntries.isNotEmpty
              ? moodProvider.moodEntries.first.mood
              : MoodType.neutral;
          response = await _aiService.getChatResponse(
            text,
            currentMood,
            moodProvider.moodEntries.take(10).toList(),
          );
          responseType = ChatMessageType.psychology;
          break;

        case UserMessageType.catInteraction:
          // 猫咪互动回复
          response = await _generateCatInteractionResponse(text, catProvider.cat);
          responseType = ChatMessageType.normal;
          break;

        case UserMessageType.casual:
          // 日常聊天回复
          response = await _generateCasualResponse(text);
          responseType = ChatMessageType.normal;
          break;

        case UserMessageType.functional:
          // 功能性回复
          response = _generateFunctionalResponse(text);
          responseType = ChatMessageType.system;
          break;
      }

      // 添加AI回复
      setState(() {
        _messages.add(ChatMessage(
          text: response,
          isUser: false,
          timestamp: DateTime.now(),
          avatar: _getResponseAvatar(responseType),
          messageType: responseType,
        ));
        _isTyping = false;
      });

      _scrollToBottom();
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          text: '抱歉，我现在有点忙，请稍后再试。但请记住，你的感受很重要，我会一直在这里支持你。💙',
          isUser: false,
          timestamp: DateTime.now(),
          avatar: '🤖',
        ));
        _isTyping = false;
      });
    }
  }

  /// 分析用户消息类型
  UserMessageType _analyzeMessageType(String message) {
    final lowerMessage = message.toLowerCase();

    // 心理支持关键词
    final psychologyKeywords = [
      '难过', '伤心', '焦虑', '担心', '害怕', '抑郁', '压力', '烦恼',
      '不开心', '痛苦', '困扰', '迷茫', '失望', '绝望', '孤独', '无助',
      '心情', '情绪', '感受', '心理', '精神', '内心', '想法'
    ];

    // 猫咪互动关键词
    final catKeywords = [
      '猫', '猫咪', '小猫', '喵', '宠物', '陪伴', '可爱', '毛茸茸',
      '抚摸', '拥抱', '玩耍', '互动'
    ];

    // 功能性关键词
    final functionalKeywords = [
      '记录', '旅行', '心情记录', '设置', '帮助', '功能', '怎么用',
      '如何', '教程', '指南'
    ];

    // 检查心理支持
    if (psychologyKeywords.any((keyword) => lowerMessage.contains(keyword))) {
      return UserMessageType.psychology;
    }

    // 检查猫咪互动
    if (catKeywords.any((keyword) => lowerMessage.contains(keyword))) {
      return UserMessageType.catInteraction;
    }

    // 检查功能性
    if (functionalKeywords.any((keyword) => lowerMessage.contains(keyword))) {
      return UserMessageType.functional;
    }

    // 默认为日常聊天
    return UserMessageType.casual;
  }

  /// 生成猫咪互动回复
  Future<String> _generateCatInteractionResponse(String message, cat) async {
    if (cat == null) {
      return '喵~ 我还没有遇到我的猫咪伙伴呢！你想帮我找一只可爱的猫咪吗？🐱';
    }

    final responses = [
      '${cat.name}听到你的声音就开心地摇尾巴~ 喵喵！🐱',
      '喵~ ${cat.name}想要和你一起玩耍！你想做什么呢？',
      '${cat.name}轻轻蹭了蹭你的手，表示很喜欢你~ 💕',
      '喵呜~ ${cat.name}觉得和你聊天很开心！',
      '${cat.name}伸了个懒腰，然后跳到你身边坐下~ 🐾',
    ];

    return responses[DateTime.now().millisecond % responses.length];
  }

  /// 生成日常聊天回复
  Future<String> _generateCasualResponse(String message) async {
    final responses = [
      '听起来很有趣！能告诉我更多吗？😊',
      '我很喜欢和你聊天！你今天过得怎么样？',
      '这让我想到了很多有趣的事情~ ✨',
      '你的想法很棒！我们继续聊聊吧~',
      '谢谢你和我分享这些！我很开心能听到你的声音 💙',
    ];

    return responses[DateTime.now().millisecond % responses.length];
  }

  /// 生成功能性回复
  String _generateFunctionalResponse(String message) {
    final lowerMessage = message.toLowerCase();

    if (lowerMessage.contains('心情记录') || lowerMessage.contains('记录心情')) {
      return '你可以点击右下角的悬浮猫咪，然后选择"心情记录"来记录你的心情哦！这样我就能更好地了解你的感受~ 💭';
    }

    if (lowerMessage.contains('旅行') || lowerMessage.contains('旅行记录')) {
      return '想记录旅行吗？点击悬浮猫咪选择"旅行记录"，或者切换到旅行页面，那里有美丽的地图等着你！🗺️';
    }

    if (lowerMessage.contains('设置') || lowerMessage.contains('功能')) {
      return '你可以通过悬浮猫咪菜单访问各种功能，或者在"我的"页面查看更多设置选项~ ⚙️';
    }

    return '我可以帮你记录心情、聊天陪伴、分享旅行故事！点击右下角的悬浮猫咪查看更多功能~ ✨';
  }

  /// 获取回复头像
  String _getResponseAvatar(ChatMessageType type) {
    switch (type) {
      case ChatMessageType.psychology:
        return '💙';
      case ChatMessageType.system:
        return '🤖';
      default:
        return '🐱';
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _openMoodRecord() {
    _toggleFunctionMenu();
    _showQuickMoodRecord();
  }

  void _showQuickMoodRecord() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => QuickMoodRecordSheet(),
    );
  }

  void _openTravelRecord() {
    _toggleFunctionMenu();
    Navigator.pushNamed(context, '/travel_record');
  }

  void _openSettings() {
    _toggleFunctionMenu();
    Navigator.pushNamed(context, '/settings');
  }
}

/// 聊天消息类型
enum ChatMessageType {
  normal,
  welcome,
  psychology,
  system,
}

/// 用户消息类型
enum UserMessageType {
  psychology,     // 心理支持
  catInteraction, // 猫咪互动
  casual,         // 日常聊天
  functional,     // 功能性询问
}

/// 聊天消息模型
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String avatar;
  final ChatMessageType messageType;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    required this.avatar,
    this.messageType = ChatMessageType.normal,
  });
}
