import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cat_provider.dart';
import '../providers/mood_provider.dart';
import '../theme/artistic_theme.dart';
import '../widgets/quick_mood_record_sheet.dart';

/// 简化版首页 - 专注于核心功能
class SimpleHomeScreen extends StatefulWidget {
  const SimpleHomeScreen({super.key});

  @override
  State<SimpleHomeScreen> createState() => _SimpleHomeScreenState();
}

class _SimpleHomeScreenState extends State<SimpleHomeScreen>
    with TickerProviderStateMixin {
  
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  
  late AnimationController _catAnimationController;
  late Animation<double> _catPulseAnimation;

  @override
  void initState() {
    super.initState();
    
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
    
    _loadWelcomeMessage();
  }

  void _loadWelcomeMessage() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _messages.add(ChatMessage(
          text: '喵~ 我是你的暖猫助手！今天想聊什么呢？我可以陪你聊天、记录心情哦~ 🐱✨',
          isUser: false,
          timestamp: DateTime.now(),
          avatar: '🐱',
        ));
      });
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _catAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ArtisticTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // 顶部标题栏
            _buildTopBar(),
            
            // 聊天消息列表
            Expanded(
              child: _buildChatList(),
            ),
            
            // 输入区域
            _buildInputArea(),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingCat(),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
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
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '暖猫 AI 助手',
                  style: ArtisticTheme.headingStyle.copyWith(fontSize: 18),
                ),
                Text(
                  '在线陪伴',
                  style: ArtisticTheme.captionStyle,
                ),
              ],
            ),
          ),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _messages.length + (_isTyping ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length && _isTyping) {
          return _buildTypingIndicator();
        }
        
        final message = _messages[index];
        return _buildMessageBubble(message);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isUser 
            ? MainAxisAlignment.end 
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            _buildAvatar(message.avatar),
            const SizedBox(width: 8),
          ],
          
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser 
                    ? ArtisticTheme.primaryColor 
                    : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                message.text,
                style: ArtisticTheme.bodyStyle.copyWith(
                  color: isUser ? Colors.white : ArtisticTheme.textPrimary,
                ),
              ),
            ),
          ),
          
          if (isUser) ...[
            const SizedBox(width: 8),
            _buildAvatar(message.avatar),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar(String emoji) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(emoji, style: const TextStyle(fontSize: 16)),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          _buildAvatar('🤖'),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text('正在输入...'),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // 心情记录按钮
          GestureDetector(
            onTap: _showQuickMoodRecord,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.pink.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.pink.withValues(alpha: 0.3),
                ),
              ),
              child: const Icon(
                Icons.mood,
                color: Colors.pink,
                size: 20,
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // 输入框
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: '和我聊聊吧...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.withValues(alpha: 0.1),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // 发送按钮
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: ArtisticTheme.primaryColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.send,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingCat() {
    return AnimatedBuilder(
      animation: _catPulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _catPulseAnimation.value,
          child: FloatingActionButton(
            onPressed: _showCatMenu,
            backgroundColor: ArtisticTheme.primaryColor,
            child: const Text('🐱', style: TextStyle(fontSize: 24)),
          ),
        );
      },
    );
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isTyping) return;

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

    // 简单的回复逻辑
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            text: _generateSimpleReply(text),
            isUser: false,
            timestamp: DateTime.now(),
            avatar: '🐱',
          ));
          _isTyping = false;
        });
      }
    });
  }

  String _generateSimpleReply(String userMessage) {
    final lowerMessage = userMessage.toLowerCase();
    
    if (lowerMessage.contains('难过') || lowerMessage.contains('伤心')) {
      return '我感受到了你的难过... 虽然我只是个AI，但我想给你一个温暖的拥抱 🤗 一切都会好起来的！';
    }
    
    if (lowerMessage.contains('开心') || lowerMessage.contains('高兴')) {
      return '喵喵喵~ 看到你开心我也很高兴！你的笑容是最美的~ ✨';
    }
    
    if (lowerMessage.contains('累') || lowerMessage.contains('疲惫')) {
      return '听起来你需要好好休息~ 来，让我陪你一起放松一下 😴';
    }
    
    final replies = [
      '听起来很有趣！能告诉我更多吗？😊',
      '我很喜欢和你聊天！你今天过得怎么样？',
      '这让我想到了很多有趣的事情~ ✨',
      '你的想法很棒！我们继续聊聊吧~',
      '谢谢你和我分享这些！我很开心能听到你的声音 💙',
    ];
    
    return replies[DateTime.now().millisecond % replies.length];
  }

  void _showQuickMoodRecord() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const QuickMoodRecordSheet(),
    );
  }

  void _showCatMenu() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🐱 猫咪菜单'),
        content: const Text('更多功能正在开发中...\n\n目前可用功能：\n• 聊天对话\n• 心情记录'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }
}

/// 简化的聊天消息模型
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String avatar;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    required this.avatar,
  });
}
