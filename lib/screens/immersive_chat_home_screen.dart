import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/cat_provider.dart';
import '../providers/dialogue_provider.dart';
import '../models/cat.dart';
import '../models/dialogue.dart';
import '../theme/artistic_theme.dart';
import '../widgets/floating_cat_assistant.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/immersive_chat_widget.dart';
import '../widgets/quick_mood_record_sheet.dart';

/// 沉浸式聊天首页 - 创新设计
class ImmersiveChatHomeScreen extends StatefulWidget {
  const ImmersiveChatHomeScreen({super.key});

  @override
  State<ImmersiveChatHomeScreen> createState() => _ImmersiveChatHomeScreenState();
}

class _ImmersiveChatHomeScreenState extends State<ImmersiveChatHomeScreen>
    with TickerProviderStateMixin {

  // 聊天相关（输入与滚动控制）
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // 悬浮猫咪相关
  late AnimationController _catAnimationController;
  late Animation<double> _catPulseAnimation;
  Offset? _catPos; // 当前会话内的猫咪位置（left, top）
  String? _catPosSessionId;
  bool _catPosLoading = false;

  // 背景动画
  late AnimationController _backgroundController;
  late Animation<Color?> _backgroundColorAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
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



  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _catAnimationController.dispose();
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
            decoration: const BoxDecoration(
              gradient: AppTheme.mistSkyGradient,
            ),
            child: SafeArea(
              child: Stack(
                children: [
                  // 主聊天界面
                  _buildChatInterface(),

                  // 悬浮猫咪助手（点击直接作为“抚摸”反馈）
                  _buildFloatingCatAssistant(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildChatInterface() {
    final dialogue = context.watch<DialogueProvider>();
    final sessionMsgs = dialogue.activeSession?.messages ?? const <DialogueMessage>[];
    final messages = _mapProviderMessages(sessionMsgs);
    final isTyping = dialogue.isProcessing;

    return Column(
      children: [
        _buildTopBar(),
        Expanded(
          child: ImmersiveChatWidget(
            messages: messages,
            scrollController: _scrollController,
            isTyping: isTyping,
          ),
        ),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isNarrow = constraints.maxWidth < 360;
        final double side = isNarrow ? 44 : 48;
        final double radius = side / 2;
        final double spacing = isNarrow ? 8 : 12;
        final double horizontalPad = isNarrow ? 12 : 16;
        final double inputHPad = isNarrow ? 14 : 20;
        return Container(
          padding: EdgeInsets.all(horizontalPad),
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
                  width: side,
                  height: side,
                  decoration: BoxDecoration(
                    color: Colors.pink.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(radius),
                    border: Border.all(
                      color: Colors.pink.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.mood,
                    color: Colors.pink,
                    size: 22,
                  ),
                ),
              ),

              SizedBox(width: spacing),

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
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: inputHPad,
                        vertical: 12,
                      ),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
              ),

              SizedBox(width: spacing),

              // 发送按钮
              GestureDetector(
                onTap: _sendMessage,
                child: Container(
                  width: side,
                  height: side,
                  decoration: BoxDecoration(
                    color: ArtisticTheme.primaryColor,
                    borderRadius: BorderRadius.circular(radius),
                    boxShadow: ArtisticTheme.elevatedShadow,
                  ),
                  child: const Icon(
                    Icons.send_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _loadCatPosForSession(String sessionId) async {
    if (_catPosLoading) return;
    _catPosLoading = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('cat_pos_$sessionId');
      if (raw != null) {
        final parts = raw.split(',');
        if (parts.length == 2) {
          final dx = double.tryParse(parts[0]);
          final dy = double.tryParse(parts[1]);
          if (dx != null && dy != null && mounted) {
            setState(() => _catPos = Offset(dx, dy));
          }
        }
      }
    } finally {
      _catPosLoading = false;
    }
  }

  Future<void> _saveCatPosForSession(String sessionId, Offset pos) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cat_pos_$sessionId', '${pos.dx},${pos.dy}');
  }

  Widget _buildFloatingCatAssistant() {
    final dialogue = context.watch<DialogueProvider>();
    final hasFewMsgs = (dialogue.activeSession?.messages.length ?? 0) <= 1;
    final sessionId = dialogue.activeSession?.id;

    // 当切换到新会话时，加载存储的位置
    if (sessionId != null && _catPosSessionId != sessionId) {
      _catPosSessionId = sessionId;
      _catPos = null; // 重置为默认
      _loadCatPosForSession(sessionId);
    }

    final defaultPos = const Offset(20, 100);
    final pos = _catPos ?? defaultPos;

    return Positioned(
      left: pos.dx,
      top: pos.dy,
      child: Draggable(
        feedback: const SizedBox(width: 80, height: 80),
        childWhenDragging: const Opacity(opacity: 0.7, child: SizedBox(width: 80, height: 80)),
        onDragEnd: (details) async {
          final dx = details.offset.dx;
          // 减去安全区顶部，限制在可视范围内
          final safeTop = MediaQuery.of(context).padding.top;
          final dy = (details.offset.dy - safeTop).clamp(0.0, MediaQuery.of(context).size.height - 80);
          final newPos = Offset(dx, dy);
          setState(() => _catPos = newPos);
          if (sessionId != null) await _saveCatPosForSession(sessionId, newPos);
        },
        child: FloatingCatAssistant(
          animation: _catPulseAnimation,
          onTap: _petCatBubble,
          showNotification: hasFewMsgs,
        ),
      ),
    );
  }




  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    // 通过 DialogueProvider 发送消息（内部负责AI调用与持久化）
    final dialogue = context.read<DialogueProvider>();
    final cat = context.read<CatProvider>().cat ?? Cat(name: '小暖', breed: CatBreed.random);

    // 立刻清空输入并滚动
    _messageController.clear();
    _scrollToBottom();

    await dialogue.sendUserMessage(text, cat);
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

  void _showQuickMoodRecord() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return AnimatedBuilder(
          animation: ModalRoute.of(context)!.animation!,
          builder: (ctx, child) {
            final anim = CurvedAnimation(parent: ModalRoute.of(context)!.animation!, curve: AppTheme.easeStandard);
            return FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(anim),
                child: child,
              ),
            );
          },
          child: QuickMoodRecordSheet(),
        );
      },
    );
  }

  // 轻触猫咪：弹出性格化 Emoji 气泡
  void _petCatBubble() {
    final cat = context.read<CatProvider>().cat;
    final personality = cat?.personality;
    final list = () {
      switch (personality) {
        case CatPersonality.playful:
          return ['😸','🥰','✨','🌞'];
        case CatPersonality.social:
          return ['😹','🤪','🎉','🫶'];
        case CatPersonality.independent:
          return ['😼','🧭','🧠','👍'];
        case CatPersonality.calm:
          return ['😺','🌿','☕','💗'];
        case CatPersonality.curious:
          return ['🧐','💡','🧩','📚'];
        case CatPersonality.lazy:
          return ['😽','🌙','🎵','📖'];
        default:
          return ['🐾','💝'];
      }
    }();
    final emoji = (list..shuffle()).first;

    final overlay = Overlay.of(context);

    final entry = OverlayEntry(
      builder: (ctx) => Positioned(
        right: 26,
        bottom: 170,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 600),
          builder: (c, v, child) => Opacity(
            opacity: v,
            child: Transform.translate(
              offset: Offset(0, -30 * v),
              child: child,
            ),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 20, color: Colors.white)),
          ),
        ),
      ),
    );

    overlay.insert(entry);
    Future.delayed(const Duration(milliseconds: 900), entry.remove);
    HapticFeedback.lightImpact();
  }

}

  List<ChatMessage> _mapProviderMessages(List<DialogueMessage> msgs) {
    return msgs.map((m) => ChatMessage(
      text: m.text,
      isUser: m.sender == MessageSender.user,
      timestamp: m.timestamp,
      avatar: m.sender == MessageSender.user ? '😊' : '🐱',
      messageType: ChatMessageType.normal,
    )).toList();
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
